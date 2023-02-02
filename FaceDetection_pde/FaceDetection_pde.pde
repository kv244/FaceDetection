import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.nio.file.Files;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import java.io.FileReader;

// TODO:
// OnScreen messages better?
// Multiple images?

Capture video;
OpenCV opencv;
PImage renderedImage;
Rectangle[] faces;
String pathImage = "C:\\Users\\petrescu\\Documents\\Dev\\IMGDemo\\MsgIn_v1\\";
String pathMessage = "C:\\Users\\petrescu\\Documents\\Dev\\IMGDemo\\MsgIn_v1\\";
String pathIRISLog = "C:\\Users\\petrescu\\Documents\\Dev\\IMGDemo\\MsgOut\\Log.txt";
int secondsWait = 3;
long timeMilli;
int textX = 8;
int textY = 32;
int textHeight = 24;
BufferedReader input;

// Setup
void setup() {
  size(640, 360);
  video = new Capture(this, width, height);
  video.start();  
  timeMilli = System.currentTimeMillis();
  opencv = new OpenCV(this, video.width, video.height);  
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  try{ 
    input = new BufferedReader(new FileReader(pathIRISLog));
    // fseek end
    while(input.readLine() != null);
    print("IRIS log scanned.\n");
  }catch(Exception x){
    print("IRIS log not readable " + x.toString() + "\n");
    input = null;
  }
}

// OpenCV framework
void captureEvent(Capture c) {
  c.read();
}

// Render loop
void draw() {
  boolean tick;
  opencv.loadImage(video);
  faces = opencv.detect();
  renderedImage = opencv.getInput(); 
  image(renderedImage, 0, 0);
  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);
  
  // Imgproc.putText();
  
  int fLen = faces.length;
  boolean bFacesFound = (fLen > 0);
  
  if(bFacesFound){
    long timeDelta = System.currentTimeMillis();
    tick = (timeDelta - timeMilli >= secondsWait * 1000);
  
    text("Faces found: " + Integer.toString(fLen), textX, textY);
    for (int i = 0; i < fLen; i++) {
      rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
    }
    
    if(tick){
      timeMilli = System.currentTimeMillis();
      String st = Long.toString(timeMilli);
      String fImgName = pathImage + st + ".jpg";
      String fMsgName = pathMessage + st + ".txt";
      if(!saveScreen(fImgName, faces)){
        print("Image save failed - not submitted for recognition.\n");
        return;
      };
      makeMessage(fMsgName, fImgName);
    }
  }
}

// Save identified image(s)
// For now will only save one image (the first rectangle from the parameter list)
// Saving all means handling the names a bit differently
boolean saveScreen(String imgPath, Rectangle[] ptrFaces){
  Rectangle savedRect = ptrFaces[0];
  BufferedImage biRenderedImage = (BufferedImage)renderedImage.getNative();
  BufferedImage biSavedImage = biRenderedImage.getSubimage(savedRect.x, 
    savedRect.y, savedRect.width, savedRect.height);
  File outputFile = new File(imgPath);
  text("Saving: " + imgPath, textX, textY + textHeight * 2);
  // print("Saving: " + imgPath + "\n");
  
  try{
    ImageIO.write(biSavedImage, "jpg", outputFile);
  }
  catch(Exception e){
    text("Failed: " + e.toString(), textX, textY + textHeight * 3);
    print("Failed to save: " + e.toString() + "\n");
    return false;
  }
  text("Done.", textX, textY + textHeight * 3);
  checkLog();
  return true;
}

void checkLog(){
  // TODO more... check time last updated, and if can read
  if(input == null) return;
  
  String currentLine;
  try{
  if ((currentLine = input.readLine()) != null)
    println("IRIS response: " + currentLine);
  }catch(Exception x){
    print("IRIS Log read error: " + x.toString() + "\n");
  }
}

// Create message for facial recognition server
boolean makeMessage(String msgFile, String imgFile){
  String content = "who," + imgFile; 
  
  File outputFile = new File(msgFile);
  text("Checking: " + imgFile, textX, textY + 4 * textHeight);
  // print("Checking: " + imgFile + "\n");
  try (
    final BufferedWriter writer = Files.newBufferedWriter(outputFile.toPath(),
            java.nio.charset.StandardCharsets.UTF_8, 
            java.nio.file.StandardOpenOption.CREATE);
    ){
        writer.write(content);
        writer.flush();
        text("Submitted: " + imgFile, textX, textY + 4 * textHeight);
        print("Submitted: " + imgFile + " in " + msgFile + "\n");
    }catch(Exception e){
      text("Failed to submit request: " + e.toString(), textX, textY + 4 * textHeight);
      print("Failed to submit request: " + e.toString() + "\n");
      return false;
    }
 
  return true;
}
