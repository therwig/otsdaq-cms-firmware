#include <iostream>
#include <string>
#include <string.h>     /* strlen */
#include <stdlib.h>     /* strtoul */
#include <vector>
#include <stdio.h>
#include <stdio.h>
#include <sstream>

using namespace std;

int main(int argc, char **argv)
{

  const std::string OUTPUT_FILE_RADIX = "sim_input_fiber_";

  if(argc != 3)
    {
      cout << "Need one argument for input file and output path." << endl;
      return -1;
    }

  std::vector<std::vector<unsigned long long> > links;
  for(unsigned int i=0;i<48;++i)
    links.push_back(std::vector<unsigned long long>()); //create empty link

  { //start read in links
    FILE *fp = fopen(argv[1],"r");
    if(!fp)
      {
	cout << "File could not be opened: " << argv[1] << endl;
	return -1;
      }
    
    const unsigned int LINE_SZ = 2000;
    char line[LINE_SZ];


    unsigned long long tmp;

    //skip first header lines
    for(unsigned int i=0;i<3;++i)
      fgets(line,LINE_SZ,fp);


    while(fgets(line,LINE_SZ,fp))
      {
	//cout << line << endl;
	unsigned int length = strlen(line);
	unsigned int j=0;
	unsigned int l=0;
	for(unsigned int i=0;i<length;++i)
	  {
	    //cout << j << "-" << i << endl;
	    if(j==i && line[i] == ' ')
	      { //find first char in next word
		
		++j; continue;
	      }


	    //cout << line[i] << endl;
	    if(line[i] == ' ')
	      line[i] = '\0';
	    else 
	      continue;
	    
	    tmp = strtoul(&line[j], 0, 16);
	    if(0 && l>0)
	      cout << dec << l-1 <<  ": 0x" << hex << tmp << endl;

	    //if (l == 5) return -1;
	    if(l > 48)
	      {
		cout << "Impossible link!" << endl;
		return -1;
	      }

	    if(l>0) //skip first value
	      links[l-1].push_back(tmp);

	    ++l;

	    j = i+1;


	  }
	
	if(0) //debug link row
	  {
	    for(unsigned int i=0;i<48;++i)
	      if(links[i].size() == links[0].size())
		cout << "0x" << hex << links[i].back() << " ";
	      else
		{
		  cout << "link" << i << "Missing!!!!!" << endl;
		  return -1;
		}
	    cout << endl;
	    return -1;
	  }
	//sscanf(line,lineMask.c_str(),
      } //end read line loop

    cout << "Entries per link: " << dec << links[0].size() << hex << " 0x" << links[0].size() << endl;

    fclose(fp);
  } //end read in links


  
  { //start output of links
    //    OUTPUT_FILE_RADIX
    
   
    // add valid bit by group
    const unsigned int GROUP_LINK_COUNT = 42/3;
    
    //double the 48 links to 96 links

    unsigned int link_file_index = 0;

    cout << "Link count = " << dec << links.size() << endl;
    for(unsigned int l=0;l<42 && //specify max number of links
	  l<links.size();++l)
      {
	for(unsigned int m=0;m< (l%GROUP_LINK_COUNT == 0?6:2) ;++m) //duplicate file to get to 96 links (for first, duplicated 12 times)
	  {
	    std::stringstream filename;
	    filename << argv[2] << "/" << OUTPUT_FILE_RADIX << link_file_index++ << ".dat";
	    FILE *fp = fopen(filename.str().c_str(),"w");
	    if(!fp)
	      {
		cout << "File could not be opened for output: " << filename.str() << endl;
		return -1;
	      }
	    
	    for(unsigned int i=0;i<108 && //specify max number of link words
		  i<links[l].size();++i)
	      {
		//add valid bit by group
		if(i >= l/GROUP_LINK_COUNT * 18)
		  fprintf(fp,"1");
		else
		  fprintf(fp,"0");
		
		fprintf(fp,"%16.16llX\n",links[l][i]);
		
		//	    cout << hex << links[l][i] << endl;
	      }
	    fclose(fp);
	  }
      }
  }

  //first way for output
  if(0)
    {
    FILE *fp = fopen(argv[2],"w");
    if(!fp)
      {
	cout << "File could not be opened for output: " << argv[2] << endl;
	return -1;
      }

    unsigned int t=0;
    for(unsigned int i=0;i<links[0].size();++i)
      {
	for(unsigned int j=0;j<3;++j)
	  {	    
	    for(unsigned int l=0;l<links.size();++l)
	      fprintf(fp,"0x%16.16X ",links[l][i]);
	    fprintf(fp,"\n");
	    ++i;
	  }
	for(unsigned int j=0;j<15;++j)
	  {	    
	    for(unsigned int l=0;l<links.size();++l)
	      fprintf(fp,"0x%20.20X ",0);//links[l][i]);
	    fprintf(fp,"\n");
	    //++i;
	  }
      }

    fclose(fp);
  } //end output of links


  cout << "Done." << endl;

  return 0;
}
