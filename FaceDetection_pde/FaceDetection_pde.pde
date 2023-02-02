import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.nio.file.Files;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;

// TODO:
// Check message making
// Check paths (image, message)
// Do response (replicate listening to file in IRIS?)
// OnScreen messages better?
// Multiple images?

Capture video;
OpenCV opencv;
PImage renderedImage;
Rectangle[] faces;
String pathImage = "";
String pathMessage = "";
int secondsWait = 3;
long timeMilli;
int textX = 8;
int textY = 32;
int textHeight = 24;

// Setup
void setup() {
  size(640, 360);
  video = new Capture(this, width, height);
  video.start();  
  timeMilli = System.currentTimeMillis();
  opencv = new OpenCV(this, video.width, video.height);  
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
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
  print("Saving: " + imgPath + "\n");
  
  try{
    ImageIO.write(biSavedImage, "jpg", outputFile);
  }
  catch(Exception e){
    text("Failed: " + e.toString(), textX, textY + textHeight * 3);
    print("Failed to save: " + e.toString() + "\n");
    return false;
  }
  text("Done.", textX, textY + textHeight * 3);
  return true;
}

// Create message for facial recognition server
boolean makeMessage(String fName, String imgPath){
  // may need to replace \\ path to match what IRIS expects
  String content = "who," + imgPath + "\\" + fName;
  
  File outputFile = new File(fName);
  text("Checking: " + imgPath, textX, textY + 4 * textHeight);
  print("Checking: " + imgPath + "\n");
  try (
    final BufferedWriter writer = Files.newBufferedWriter(outputFile.toPath(),
            java.nio.charset.StandardCharsets.UTF_8, 
            java.nio.file.StandardOpenOption.CREATE);
    ){
        writer.write(content);
        writer.flush();
        text("Submitted: " + imgPath, textX, textY + 4 * textHeight);
        print("Submitted: " + imgPath + "\n");
    }catch(Exception e){
      text("Failed to submit request: " + e.toString(), textX, textY + 4 * textHeight);
      print("Failed to submit request: " + e.toString() + "\n");
      return false;
    }
 
  return true;
}
