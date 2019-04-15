/*
 * This macro measures the facet sizes of QXF cables.
 * It also identifies possible crossovers at the edges.
 * Open any image from the folder that contains all
 * the cable images, select the starting image below
 * and run.
 */
MacroVersion = "Facet Size";//This text will be the filename of your results, if you want add the cable ID
startingimage = 0;//Use this to filter out out-of-frame images and labels at the beginning
dir = getDirectory("image");//creates a variable with the directory folder
close();//closes the current image and starts with the "startingimage"
list=getFileList(dir);//This part creates an array with the number of images (items) in the directory folder


/*
We need to create the final arrays that will hold the Feret values.
These will be used at the end
 */

NumberOfFolders = 1;
NumberOfMeasurements = newArray(list.length-NumberOfFolders);

AverageFeret = newArray(list.length-NumberOfFolders);
MinimumFeret = newArray(list.length-NumberOfFolders);
MaximumFeret = newArray(list.length-NumberOfFolders);
FeretStandardDeviation = newArray(list.length-NumberOfFolders);
AverageHeight = newArray(list.length-NumberOfFolders);

AverageMiniFeret = newArray(list.length-NumberOfFolders);
MinimumMiniFeret = newArray(list.length-NumberOfFolders);
MaximumMiniFeret = newArray(list.length-NumberOfFolders);
MiniFeretStandardDeviation = newArray(list.length-NumberOfFolders);

ImageNumber = newArray(list.length-NumberOfFolders);
ImageName = newArray(list.length-NumberOfFolders);

/*
The for loop below applies the macro to each image in the directory folder.
We use variable "o" since "i" often gets overwritten.
Notice I'm subtracting the number of folders in the root folder.
I try to keep it to only one called Processed.
*/

for(o=startingimage;o<list.length-NumberOfFolders;o++){ 
open(dir+list[o]); 
getDimensions(width, height, channels, slices, frames);//gets the dimensions of the image


/*
The step below saves the image title (without the file extension)
which will be reused to save binary images and results under the same name.
It also saves the file extension.
Whenever you decide to save an image you must add the name of the subfolder
and the variable for the file extension. For example: 
saveAs(extension, dir+"\\lines\\"+title+extension);
*/

name=getTitle;//Gets filename with extension
dotIndex = indexOf(name, "."); //Looks for the dot and gives it an index number
title = substring(name, 0, dotIndex);//truncates the name string at the dot index number
extension = substring(name, dotIndex, dotIndex+4);//truncates the name string from the dot to four characters after the dot (includes the dot)
index = lastIndexOf(name, "\\");//I think this line and the next one are making sure the name starts after the last forward slash
if (index!=-1) name = substring(name, 0, index);



/*
 * The two prisms have slightly different boundaries so we have to treat them differently
 */


if (matches(title, ".*Cam1.*")) {
makeRectangle(5, 0, 150, height);//for prisms
run("Crop");
run("Canvas Size...", "width="+width+" height="+height+" position=Top-Left zero");
}

if (matches(title, ".*Cam2.*")) {
makeRectangle(10, 0, 120, height);//for prisms
run("Crop");
run("Canvas Size...", "width=200 height="+height+" position=Top-Right zero");//add the two values on the rectangle
run("Canvas Size...", "width="+width+" height="+height+" position=Top-Left zero");
}



/*
The step below avoids black images
 */
run("Clear Results"); 
run("Measure");
if (getResult("Mean")<10)//in case there is a black image it just closes it
    {
     run("Close All");
    }
    	else{



/*
The step below thresholds the image, inverts it, makes binary again
(since sometimes they are made into LUTs), and fills holes
*/
setAutoThreshold("Default");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Invert");
run("RGB Color");
run("8-bit");
run("Fill Holes");

/*
 The step below duplicates the image,
 erodes a bunch of times and dilates even more times.
 Then merges the image using the conservative
 approach
 */
run("Duplicate...", "copy");
run("Erode");
run("Erode");
run("Erode");
run("Erode");
run("Erode");
run("Erode");
run("Erode");
run("Analyze Particles...", "size=100-Infinity circularity=0.1-1.00 show=Masks display clear");//This gets rid of very long features and very small features
selectWindow(title+"-1"+extension);
close();
run("Dilate");
run("Dilate");
run("Dilate");
run("Dilate");
run("Dilate");
run("Dilate");
run("Dilate");
run("Dilate");
run("Dilate");
run("Dilate");
run("Dilate");
run("Images to Stack", "name=Stack title=[] use");
run("Z Project...", "projection=[Max Intensity]");
selectWindow("Stack");
close();

/*
The step below makes sure the above image is black features in white background
 */

run("Make Binary");
run("RGB Color");
run("8-bit");
run("Clear Results");
makeRectangle(0, 0, 20, 12);
run("Measure");
run("Select None");

if (getResult("Mean")<10)
    {
     run("Invert");
    }
    	else{};

/*
The step below finds the largest area and creeates a variable
to be used later for removing small features
*/

run("Analyze Particles...", "display clear");
largestfeature = 0;
for (a=0; a<nResults(); a++) {
    if (getResult("Area",a)>largestfeature)
    {
     largestfeature = getResult("Area",a);
    	}
    	else{};
}

/*
The step below removes the small features and 
makes binary again.
Note: the current threshold for small features is
10% of the largest features.
*/


smallfeatures = largestfeature*0.1;//this value will be used in the step below
run("Analyze Particles...", "size="+smallfeatures+"-Infinity show=Masks display exclude clear");

/*
 * The step below counts the number of facets and if there are less than 7 it saves the image as a potential crossover
 *  
 */
 
NumberOfFacets = newArray(nResults);

if (nResults()<7)//this counts the facets and saves images which have less than 7 facets as possible crossovers
    {
 	open(dir+list[o]);
	saveAs("PNG", dir+"\\Processed\\Crossovers\\Counting facets\\"+title+".png");
	close();   	
    }
		else{};
			
run("RGB Color");
run("8-bit");
saveAs("PNG", dir+"\\Processed\\Facets\\"+title+".png");
selectWindow("MAX_Stack");//closes the previous image
close();


/*
 * The step below remeasures but this time rejecting those with a feret diameter that is clearly out of range
 * 
 */

if (matches(title, ".*Cam1.*")) {
run("Analyze Particles...", "size="+smallfeatures+"-Infinity show=Masks display exclude clear");
bypass = 0;// we check for crossovers, this bypass helps to save the crossover image only once (saves time)
marker = 0;//this marker and the for loop below are used to reject the out of bound facets
for(i=0; i<nResults; i++)
	{
	if(getResult("Feret", i)>105 && getResult("Feret", i)<143)//counts only facets inbound
	{
	marker = marker + 1;
	}
			else{
				if(bypass == 0 && getResult("Feret", i)>143)
				{
				open(dir+list[o]);
				saveAs("PNG", dir+"\\Processed\\Crossovers\\Counting facets\\"+title+".png");
				close();
				bypass = bypass + 1;
				}
				else{};
				};
	}

TempFeretArray = newArray(nResults);
TempMiniFeretArray = newArray(nResults);
TempHeightArray = newArray(nResults);
FeretArray = newArray(marker);
MiniFeretArray = newArray(marker);
HeightArray = newArray(marker);
marker = 0;

for(i=0; i<nResults; i++)//this combination of for and if loop doesn't take out of bound facets into the statistical measurements
	{
	TempFeretArray[i] = getResult("Feret", i);
	TempMiniFeretArray[i] = getResult("MinFeret", i);
	TempHeightArray[i] = getResult("Height", i);
		if(getResult("Feret", i)>105 && getResult("Feret", i)<143)//counts only facets inbound
		{
		FeretArray[marker] = TempFeretArray[i];
		MiniFeretArray[marker] = TempMiniFeretArray[i];
		HeightArray[marker] = TempHeightArray[i];
		marker = marker + 1;
		}
			else{};
	}

}


if (matches(title, ".*Cam2.*")) {
run("Analyze Particles...", "size="+smallfeatures+"-Infinity show=Masks display exclude clear");
bypass = 0;// we check for crossovers, this bypass helps to save the crossover image only once (saves time)
marker = 0;//this marker and the for loop below are used to reject the out of bound facets
for(i=0; i<nResults; i++)
	{
	if(getResult("Feret", i)>81 && getResult("Feret", i)<130)//counts only facets inbound
	{
	marker = marker + 1;
	}
			else{
				if(bypass == 0 && getResult("Feret", i)>130)
				{
				open(dir+list[o]);
				saveAs("PNG", dir+"\\Processed\\Crossovers\\Counting facets\\"+title+".png");
				close();
				bypass = bypass + 1;
				}
				else{};				
				};
	}

TempFeretArray = newArray(nResults);
TempMiniFeretArray = newArray(nResults);
TempHeightArray = newArray(nResults);
FeretArray = newArray(marker);
MiniFeretArray = newArray(marker);
HeightArray = newArray(marker);
marker = 0;

for(i=0; i<nResults; i++)//this combination of for and if loop doesn't take out of bound facets into the statistical measurements
	{
	TempFeretArray[i] = getResult("Feret", i);
	TempMiniFeretArray[i] = getResult("MinFeret", i);
	TempHeightArray[i] = getResult("Height", i);
		if(getResult("Feret", i)>81 && getResult("Feret", i)<130)//counts only facets inbound
		{
		FeretArray[marker] = TempFeretArray[i];
		MiniFeretArray[marker] = TempMiniFeretArray[i];
		HeightArray[marker] = TempHeightArray[i];
		marker = marker + 1;
		}
			else{};
	}

}


/*
 * After getting all the results they are made into arrays and then
 * added into the master array for each image.
 */



Array.getStatistics(FeretArray, MinFeret, MaxFeret, AveFeret, FeretStdDev);
Array.getStatistics(MiniFeretArray, MinMiniFeret, MaxMiniFeret, AveMiniFeret, MiniFeretStdDev);
Array.getStatistics(HeightArray, MinHeight, MaxHeight, AveHeight, HeightStdDev);

NumberOfMeasurements[o] = marker;

AverageFeret[o] = AveFeret;
MinimumFeret[o] = MinFeret;
MaximumFeret[o] = MaxFeret;
AverageHeight[o] = AveHeight;
FeretStandardDeviation[o] = FeretStdDev;

AverageMiniFeret[o] = AveMiniFeret;
MinimumMiniFeret[o] = MinMiniFeret;
MaximumMiniFeret[o] = MaxMiniFeret;
MiniFeretStandardDeviation[o] = MiniFeretStdDev;
ImageName[o] = title;
ImageNumber [o] = o;
Table.showArrays("Feret Statistics", ImageName, ImageNumber, NumberOfMeasurements, AverageFeret, MinimumFeret, MaximumFeret, FeretStandardDeviation, AverageMiniFeret, MinimumMiniFeret, MaximumMiniFeret, MiniFeretStandardDeviation, AverageHeight);
Table.save(dir+"\\Processed\\Facets\\Results\\"+MacroVersion+" Results.txt");
ImageNumber[o] = o+1;

run("Close All");
};//closes the if loop for black images
};//closes the for loop