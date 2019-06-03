/**********************************************
 *
 * Tool used to generate a pin constraints file
 *  from the FPGA pins 
 *
 * To get pin files:
 *   wget https://www.xilinx.com/support/packagefiles/usapackages/usaall.zip
 *   unzip usaall.zip
 *
 * To compile:
 *   g++ pin_tool.cpp
 *   
 * To run:
 *   ./a.out <path to all pin folder> <fpga name> <number of inputs> <number of outputs>
 *
 *    e.g.:
 *         ./a.out ../usaall xcvu9p-flgb2104-2-i 96 96
 * 
 * written by rrivera at fnal dot gov May 2019
 *********************************************/

#include <iostream>
#include <string>
#include <stdio.h>  /* printf, fgets */
#include <stdlib.h> /* atoi */
#include <vector>

using namespace std;

int main(int argc, char* argv[])
{
  if(argc != 5)
    {
      cout << "need target FPGA and precision strings." << endl;
      return -1;
    }

  string pinPath = argv[1];
  string fpga = argv[2];
  int inputs = atoi(argv[3]);
  int outputs = atoi(argv[4]);

  cout << "pinPath = " << pinPath << endl;
  cout << "fpga = " << fpga << endl;
  cout << "inputs = " << inputs << endl;
  cout << "outputs = " << outputs << endl;
  

  unsigned int i = fpga.length()-2;
  while(i >= 0)
    {
      //cout << i << " " << fpga[i] << endl;
      if(fpga[i] != '-') break;
      i-=2;
    }
  
  string pkg = "";
  for(unsigned int j=0;j<i+2;++j)
    if(fpga[j] != '-')
      pkg += fpga[j];
  pkg += "pkg.txt";
  
  cout << "package file = " << pkg << endl;
  
  FILE *fp = fopen((pinPath + "/" + pkg).c_str(),"r");
  if(!fp)
    {
      cout << "Invalid file path " << endl;
      return -1;
    }

  char line[500];
  i = 0;

  char pin[10];
  char type[100];
  char name[100];

  vector<string> pins;
  vector<string> types;
  
  unsigned int pinCnt = 0;
  while(fgets(line,500,fp))
    {
      if(i++<3) continue; //skip headers
      //cout << line;

      sscanf(line,"%s %s %*s %*s %s",pin,name,type);

      if(type[0] != 'H' || name[0] != 'I')
	continue;

      //cout << "pin " << pin << " type " << type << endl;
      pins.push_back(string(pin));
      types.push_back(string(type));
      ++pinCnt;
    }

  fclose(fp);

  cout << "pinCnt = " << pinCnt << endl;

  const unsigned int inputCnt = inputs;
  const unsigned int outputCnt = outputs;
  const unsigned int extraInCnt = 3;
  const unsigned int extraOutCnt = 0;

  const unsigned int totalCnt = inputCnt + outputCnt + extraInCnt + extraOutCnt;

  cout << "Need pin count = " << totalCnt << endl;

  if(pinCnt < totalCnt)
    {
      cout << "Not enough pins!" << endl;
      return -1;
    }

  fp = fopen("pins.tcl","w");
  if(!fp)
    {
      cout << "Invalid file path " << endl;
      return -1;
    }

  //handle input pins
  pinCnt = 0;

  fprintf(fp,"set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets link_clk_ibufg/O]\n");
  //fprintf(fp,"set_max_delay 5000.00 -to [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ *INPUT_SIG*)}]\n");
  //fprintf(fp,"set_max_delay 5000.00 -to [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ *OUTPUT_SIG*)}]\n");

  //fprintf(fp,"create_clock -name clk -period 7 -waveform {0 3.0} [get_ports EXTRA_INPUT_PADS[0]]\n\n\n");

  string extraInNames[] = {"link_clk_port", "reset_port", "algo_reset_port"};
  for(i=0;i< extraInCnt; ++i, ++pinCnt)
    {
      fprintf(fp,"set_property PACKAGE_PIN %s [get_ports %s]\n",
	      pins[pinCnt].c_str(),
	      extraInNames[i].c_str()
	      );
      fprintf(fp,"set_property IOSTANDARD LVCMOS18 [get_ports %s]\n", 
	      extraInNames[i].c_str()
	      );
    }

  for(i=0;i< inputCnt; ++i, ++pinCnt)
    {
      fprintf(fp,"set_property PACKAGE_PIN %s [get_ports link_serial_din_port[%d]]\n",
	      pins[pinCnt].c_str(),i);
      fprintf(fp,"set_property IOSTANDARD LVCMOS18 [get_ports link_serial_din_port[%d]]\n", i);
    }

  for(i=0;i< extraOutCnt; ++i, ++pinCnt)
    {
      fprintf(fp,"set_property PACKAGE_PIN %s [get_ports EXTRA_OUTPUT_PADS[%d]]\n",
	      pins[pinCnt].c_str(),i);
      fprintf(fp,"set_property IOSTANDARD LVCMOS18 [get_ports EXTRA_OUTPUT_PADS[%d]]\n", i);
    }
  for(i=0;i< outputCnt; ++i, ++pinCnt)
    {
      fprintf(fp,"set_property PACKAGE_PIN %s [get_ports link_serial_dout_port[%d]]\n",
	      pins[pinCnt].c_str(),i);
      fprintf(fp,"set_property IOSTANDARD LVCMOS18 [get_ports link_serial_dout_port[%d]]\n", i);
    }
  fprintf(fp,"\n#create_pblock algo\n");
  fprintf(fp,"#add_cells_to_pblock [get_pblocks algo] [get_cells -quiet [list algo]]\n");
  fprintf(fp,"#resize_pblock [get_pblocks algo] -add SLICE_X20Y20:SLICE_X90Y180\n");
  fclose(fp);



  cout << "done." << endl;
  return 0;  
}
