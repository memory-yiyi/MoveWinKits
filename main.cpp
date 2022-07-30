#include<iostream>
#include<fstream>
#include<string>
#include<vector>
using namespace std;

int main(int argc, char* argv[])
{
	char ch;
	string source;
	string destination;
	string path[2];
	string goal = "Windows Kits";

	for (char i = 0; i < 2; i++)
	{
		path[i] = argv[i + 1];
		if (path[i].back() != '\\')
			path[i].push_back('\\');
		path[i] += goal;
		if (i == 0)
			source = path[i];
		else if (i == 1)
			destination = path[i];
		for (int j = 0; j < path[i].size(); j++)
			if (path[i][j] == '\\')
			{
				path[i].insert(j, "\\");
				j++;
			}
	}


	string filepath(R"(dat\0.reg)");
	ifstream ifile;
	ofstream ofile(filepath);
	ofile << "Windows Registry Editor Version 5.00\n" << endl;

	string str;
	size_t strit;
	vector<string> content;
	// bool head = false;
	bool body = false;

	for (char name = '1'; name <= '5'; name++)
	{
		filepath[4] = name;
		ifile.open(filepath);
		if (ifile.fail())
		{
			cerr << "Failed to open file." << endl;
			return 0;
		}
		while (ifile.get(ch))
		{
			str.push_back(ch);
			if (ch == '\n')
			{
				if (str[0] == '[')// if (head)
				{
					if (body)
					{
						body = false;
						for (int i = 0; i < content.size(); i++)
							ofile << content[i];
						ofile << endl;
					}
					content.clear();
					content.push_back(str);
				}// if (head)
				else
				{
					if ((strit = str.find(path[0])) != string::npos)
					{
						body = true;
						str.replace(strit, path[0].size(), path[1]);
						content.push_back(str);
					}
				}// if (head)
				str.clear();
			}// if (ch == '\n')
		}// while (ifile.get(ch))
		ifile.close();
	}// for (char name = '1'; name <= '5'; name++)
	ofile.close();
	if (rename(source.c_str(), destination.c_str()))
	{
		cerr << "Move failed, please operate manually." << endl;
		return 0;
	}
	return 0;
}
