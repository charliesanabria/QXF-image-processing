/*
 * This macro measures the twist pitch and the  
 * inter-strand distance of QXF cables.
 * It also identifies possible crossovers.
 * Open any image from the folder that contains all
 * the cable images, select the starting image below
 * and run.
 */
MacroVersion = "Finding twist pitch";//This text will be the filename of your results, if you want add the cable ID
startingimage = 0;//Use this to filter out out-of-frame images and labels at the beginning
dir = getDirectory("image");//creates a variable with the directory folder
close();//closes the current image and starts with the "startingimage"
list=getFileList(dir);//This part creates an array with the number of images (items) in the directory folder


/*
We need to create the final arrays that will hold the angle values.
These will be used at the end
 */

NumberOfFolders = 1;
NumberOfMeasurements = newArray(list.length-NumberOfFolders);
AverageAngle = newArray(list.length-NumberOfFolders);
MinimumAngle = newArray(list.length-NumberOfFolders);
MaximumAngle = newArray(list.length-NumberOfFolders);
AngleStandardDeviation = newArray(list.length-NumberOfFolders);
StrandDistance = newArray(list.length-NumberOfFolders);
StrandDistanceMin = newArray(list.length-NumberOfFolders);
StrandDistanceMax = newArray(list.length-NumberOfFolders);
StrandDistanceStdev = newArray(list.length-NumberOfFolders);
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
makeRectangle(220, 0, 1000, height);//for prisms
run("Crop");
run("Canvas Size...", "width="+width+" height="+height+" position=Top-Right zero");

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
The step below saves the image title (without the file extension)
which will be reused to save binary images and results under the same name.
It also saves the file extension.
Whenever you decide to save an image you must add the name of the subfolder
and the variable for the file extension. For example: 
saveAs(extension, dir+"\\Processed\\lines\\"+title+extension);
*/

name=getTitle;//Gets filename with extension
dotIndex = indexOf(name, "."); //Looks for the dot and gives it an index number
title = substring(name, 0, dotIndex);//truncates the name string at the dot index number
extension = substring(name, dotIndex, dotIndex+4);//truncates the name string from the dot to four characters after the dot (includes the dot)
index = lastIndexOf(name, "\\");//I think this line and the next one are making sure the name starts after the last forward slash
if (index!=-1) name = substring(name, 0, index);

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
The step below finds the largest area and creates a variable
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
run("Analyze Particles...", "size="+smallfeatures+"-Infinity show=Masks display clear");
run("RGB Color");
run("8-bit");


/*
The step below finds the X coordinate of the first
pixel in the cable.
*/

firstx = width;//assigns a variable with the same value as the width of the image

for (a=0; a<nResults(); a++) {//goes through the BX results and assigns the smallest number to the variable
    if (getResult("BX",a)<firstx)
    {
     firstx = getResult("BX",a);
    	}
    	else{};
}

/*
The step below temporarily flips the image so that we can 
finds the X coordinate of the last pixel in the cable.
*/

run("Flip Horizontally");
run("Flip Vertically");
run("Analyze Particles...", "display clear");
run("RGB Color");
run("8-bit");

lastx = width;//assigns a variable with the same value as the width of the image
for (a=0; a<nResults(); a++) {//goes through the BX results and assigns the smallest number to the variable
    if (getResult("BX",a)<lastx)
    {
     lastx = getResult("BX",a);
    	}
    	else{};
}

run("Flip Horizontally");//flips the image back
run("Flip Vertically");

lastx = width - lastx;//the last x is now for the right image orientation

/*
The step below searches for the narrowest feature which is a safe
distance that we will use later.
*/
shortestsxwidth = width;//assigns a variable with the same value as the width of the image
for (a=0; a<nResults(); a++) {//goes through the Width results and assigns the smallest number to the variable
    if (getResult("Width",a)<shortestsxwidth)
    {
     shortestsxwidth = getResult("Width",a);
    	}
    	else{};
}

/*
If the filename has "Cam1" in it, the step below adds blank pixels to the bottom 
of the image so that the mask removes those wires that are touching the 
top of the image. Leaving only those at the minor edge of the cable (the better edge
for calculating the cable tilt)
*/
if (matches(title, ".*Cam1.*")) {
heights = height+10;
run("Canvas Size...", "width="+width+" height="+heights+" position=Top-Left");
run("Analyze Particles...", "size="+smallfeatures+"-Infinity show=Masks exclude");
run("RGB Color");
run("8-bit");

/*
Still in the if loop, the step below now selects just the pixels that are
close to the left edge. It then calculates the features rejecting the small
ones. These results will be used in the next step.

this step was removed for version 6
makeRectangle(firstx+shortestsxwidth, 0, width, height);
setForegroundColor(255, 255, 255);
run("Fill");
run("Select None");
*/

run("Analyze Particles...", "size="+smallfeatures+"-Infinity show=Nothing display clear");



/*
Still in the if loop, the step below gets the coordinates
and calculates the angles in order to rotate the image
*/

x1 = getResult("BX", 0);
y1 = getResult("BY", 0);
x2 = getResult("BX", nResults-3);//using 3 because of the left edge irregularities
y2 = getResult("BY", nResults-3);
setTool(14);
makeLine(x1,y1,x2,y2,x2+200,y2);
getSelectionCoordinates(xCoord, yCoord); 
x1=xCoord[0]; y1=yCoord[0]; 
x2=xCoord[1]; y2=yCoord[1]; 
x3=xCoord[2]; y3=yCoord[2]; 
vx1 = (x1-x2); vy1 = (y1-y2); 
vx2 = (x3-x2); vy2 = (y3-y2); 
scalarProduct=(vx1*vx2 + vy1*vy2); 
lengthProduct =sqrt((pow(vx1, 2)+pow(vy1, 2))) * sqrt((pow(vx2, 
2)+pow(vy2, 2))); 
costheta = scalarProduct/lengthProduct ; 
thetadegrees = acos(costheta)*180/PI-90; 
selectWindow("Mask of Mask of "+title+extension);
close();
selectWindow(""+title+extension);
close();
selectWindow("Mask of "+title+extension);
run("Rotate... ", "angle="+thetadegrees+" grid=1 interpolation=Bicubic fill");
run("Canvas Size...", "width="+width+" height="+height+" position=Top-Left");
saveAs("PNG", dir+"\\Processed\\Straightened+lines\\"+title+".png");
rename("straightened");
}


/*
If the filename has "Cam2" in it, this step adds blank pixels to the top 
of the image so that the mask removes those wires that are touching the 
bottom of the image. Leaving only those at the minor edge of the cable
(the better edge for calculating the cable tilt).
The difference here is that the produced binary image has to be flipped
vertically and horizontally so that the right BXs and BYs are obtained.
*/

if (matches(title, ".*Cam2.*")) {

heights = height+10;
run("Canvas Size...", "width="+width+" height="+heights+" position=Bottom-Left");
run("Analyze Particles...", "size="+smallfeatures+"-Infinity show=Masks exclude");
run("RGB Color");
run("8-bit");

/*
Still in the if loop, the step below now selects just the pixels
that are close to the right edge, flips the image, and removes features

this step was removed for version 6
makeRectangle(0, 0, lastx-shortestsxwidth, height);
setForegroundColor(255, 255, 255);
run("Fill");
run("Select None");
*/

//to get the right BX and BYs we need to flip the image 
run("Flip Horizontally");
run("Flip Vertically");


run("Analyze Particles...", "size="+smallfeatures+"-Infinity show=Nothing display clear");

//Still in the if loop, this step gets the coordinates
//and calculates the angles in order to rotate the image

x1 = getResult("BX", 0);
y1 = getResult("BY", 0);
x2 = getResult("BX", nResults-3);
y2 = getResult("BY", nResults-3);//using 3 because of the left edge irregularities
setTool(14);
makeLine(x1,y1,x2,y2,x2+200,y2);
getSelectionCoordinates(xCoord, yCoord); 
x1=xCoord[0]; y1=yCoord[0]; 
x2=xCoord[1]; y2=yCoord[1]; 
x3=xCoord[2]; y3=yCoord[2]; 
vx1 = (x1-x2); vy1 = (y1-y2); 
vx2 = (x3-x2); vy2 = (y3-y2); 
scalarProduct=(vx1*vx2 + vy1*vy2); 
lengthProduct =sqrt((pow(vx1, 2)+pow(vy1, 2))) * sqrt((pow(vx2, 
2)+pow(vy2, 2))); 
costheta = scalarProduct/lengthProduct ; 
thetadegrees = acos(costheta)*180/PI-90;
selectWindow("Mask of Mask of "+title+extension);
close();
selectWindow(""+title+extension);
close();
selectWindow("Mask of "+title+extension);
run("Rotate... ", "angle="+thetadegrees+" grid=1 interpolation=Bicubic fill");
run("Canvas Size...", "width="+width+" height="+height+" position=Top-Left");
saveAs("PNG", dir+"\\Processed\\Straightened+lines\\"+title+".png");
rename("straightened");
}


/*
Once we have the straightened version, it wil need to be binary to measure,
but sometimes it gets inverted.
The step below makes sure it doesn't
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
 * The step below does a quick angle check and in the case of a high angle it saves the image in
 * the crossovers folder
 */
TrimmingBuffer=25;
makeRectangle(firstx+TrimmingBuffer, 0, lastx-firstx-2*TrimmingBuffer, height);//trimming the edges
run("Analyze Particles...", "size="+smallfeatures+"-Infinity show=Nothing display clear");
run("Select None");
AngleCheck = 110;
bypass = 0; //this moves to the next image once the first high angle is found which saves time if multiple wires have high angles (e.g. the tilt correction was not successful)
for (a=0; a<nResults(); a++) {
    if (getResult("Angle",a)>AngleCheck)
    {
    	if (bypass == 0){
		open(dir+list[o]);
		saveAs("PNG", dir+"\\Processed\\Crossovers\\Using Angles\\"+title+".png");
		close();
		bypass = bypass + 1;
    	}
    	else{};
    }
    	else{};
}

/*
The step below obtains the average angle of the lines.
First we select wires that are close to full size using circularity.
*/

run("Analyze Particles...", "size=0-Infinity circularity=0.00-0.06 show=Masks display clear");//this selects only the largest wires
selectWindow("straightened");//closes the previous image
close();


/*
Because the prisms make a funky shape on the left side we have to reject those features
on the left edge
*/

run("Canvas Size...", "width="+width*3/4+" height="+heights+" position=Center-Right");
run("Analyze Particles...", "show=Masks display exclude clear");
run("Canvas Size...", "width="+width+" height="+height+" position=Center-Right");
selectWindow("Mask of straightened");//closes the previous image
close();

/*
The step below skeletonizes and cuts so that the tops and bottoms
dont interfere with the angle calculation. It saves the image
that is to be measured later on containing only skeletonized
lines of the wires.
*/

run("Dilate");
run("Dilate");
run("Skeletonize");
makeRectangle(0, height/4, width, height/2);
run("Crop");
run("Select None");
run("Canvas Size...", "width="+width+" height="+height+" position=Center");
run("Analyze Particles...", "size="+shortestsxwidth+"-Infinity show=Masks display clear");//we have to get rid of small features
makeRectangle(0, height/4+10, width, height/2-20);
run("Crop");
run("Select None");
run("Canvas Size...", "width="+width+" height="+height+" position=Center");
run("RGB Color");
run("8-bit");
saveAs("PNG", dir+"\\Processed\\lines\\"+title+".png");
selectWindow("Mask of Mask of straightened");//closes the previous image
close();

/*
The step below opens the straightened image and overlays the lines
in case we want to check how well the image was straightened
and how the skeleton lines look
 */
open(dir+"\\Processed\\Straightened+lines\\"+title+".png");
run("Images to Stack", "name=Stack title=[] use");
run("Next Slice [>]");
run("Invert", "slice");
run("Subtract...", "value=200 slice");
run("Invert", "slice");
run("Z Project...", "projection=[Min Intensity]");
run("Select Bounding Box");
run("Crop");
saveAs("PNG", dir+"\\Processed\\Straightened+lines\\"+title+".png");
run("Close All");



/*
The step below gets the statistics from the angle values
of the current image and it adds them to the arrays
we created at the beginning at the current marker "o".
It then prints it as a table and saves.
Firse we want to get rid of those lines which
skeletonized with too many branches. We use roundness for this.
*/

open(dir+"\\Processed\\lines\\"+title+".png");
run("Analyze Particles...", "display clear");  

marker = 0;//this marker and the for loop below are used to find out how many wires are not creepy looking (often wires with sharpie on them)
for(i=0; i<nResults; i++)
	{
	if(getResult("Round", i)<0.006 && getResult("Angle", i)>108 && getResult("Angle", i)<110)//filter in case of creepy looking wires (sharpie)
	{
	marker = marker + 1;
	}
			else{};
	}

TempAngleArray = newArray(nResults);
AngleArray = newArray(marker);
marker = 0;

     
for(i=0; i<nResults; i++)//this combination of for and if loop rejects those wires with too many branches (Roundness over 0.006)
	{
	TempAngleArray[i] = getResult("Angle", i);
		if(getResult("Round", i)<0.006 && getResult("Angle", i)>108 && getResult("Angle", i)<110)//filter in case of creepy looking wires (sharpie)
		{
		AngleArray[marker] = TempAngleArray[i];
		marker = marker + 1;
		}
			else{};
	}

Array.getStatistics(AngleArray, MinAngle, MaxAngle, AveAngle, AngleStdDev);
/*
 * The step below adds the results to the master array that contains all images.
 */
NumberOfMeasurements[o] = nResults;
AverageAngle[o] = AveAngle;
MinimumAngle[o] = MinAngle;
MaximumAngle[o] = MaxAngle;
AngleStandardDeviation[o] = AngleStdDev;

    	
run("Close All");

    	
/*
 * The step blow extracts the strand distance by opening one of the
 * images we saved below, trimming it, and rotating the frame 
 * to get the Y values
 */

 
open(dir+"\\Processed\\Straightened+lines\\"+title+".png");
run("Invert");
run("Multiply...", "value=100");
run("Invert");
makeRectangle(0, 0, 100, 1500);
setForegroundColor(255, 255, 255);
run("Fill", "slice");
makeRectangle(750, 0, 150, 1500);
run("Fill", "slice");
run("Select None");
run("Rotate... ", "angle="+AveAngle+" grid=1 interpolation=Bicubic fill enlarge");
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
 * This step measures and calculates the average distance between wires (Y, since it's rotated)
 */

run("Analyze Particles...", "size="+smallfeatures+"-Infinity show=Nothing display clear");


DistanceArray = newArray(15);//this one collects only some measurements since there will be some invalid measurements because of missing wires (sharpie)
marker = 0;
if(nResults>1)
{
TempDistanceArray = newArray(nResults-1);//this one collects all measurements

for(i=0; i<nResults-1; i++) {
	TempDistanceArray[i]= -getResult("Y", i)+getResult("Y", i+1);
	if(marker<15) //making sure there are more available measurements than acceptable measurements
	{
	if(TempDistanceArray[i]<50)//filter in case of missing wires
	{
	if(getResult("Solidity", i)>0.8)//filter in case of creepy looking wires (sharpie)
	{
	DistanceArray[marker] = TempDistanceArray[i];
	marker = marker + 1;
	}
		else{};
	}	
		else{};
	}
		else{};
	}
}
else{};

Array.getStatistics(DistanceArray, MinDistance, MaxDistance, Avedistance, DistanceStdDev);
StrandDistance[o] = Avedistance;
StrandDistanceMin[o] = MinDistance;
StrandDistanceMax[o] = MaxDistance;
StrandDistanceStdev[o] = DistanceStdDev;
/*
 * This spits out all the data
 */

ImageName[o] = title;
ImageNumber [o] = o;
Table.showArrays("Angle Statistics", ImageName, ImageNumber,NumberOfMeasurements, AverageAngle, MinimumAngle, MaximumAngle, AngleStandardDeviation, StrandDistance, StrandDistanceMin, StrandDistanceMax, StrandDistanceStdev);
Table.save(dir+"\\Processed\\lines\\Results\\"+MacroVersion+" Results.txt");
ImageNumber[o] = o+1;    	
run("Close All");
};//closes the if loop for black images
};//closes the for loop
