//importeer sound library
import processing.sound.*;

//importeer kinect library
import java.util.Map;
import java.util.Iterator;
import SimpleOpenNI.*;

//kinect connectie
SimpleOpenNI context;

//maak een lijst met alle handposities
int handVecListSize = 20;
Map<Integer,ArrayList<PVector>>  handPathList = new HashMap<Integer,ArrayList<PVector>>();



//globale variables

// x en y is voor het particle systeem de muis te laten volgen
float x;
float y;
// vertraging waarin de muis wordt gevolgd
float easing = 0.05;
//afstand tot het midden van het scherm
float distance;

// achtergrond kleur
color bg = color(0,0,0);
// kleur nummer voor de bellen
int bubbleColor;

//particle systeem
ParticleSystem ps;

//microfoon input
AudioIn input;
Amplitude analyzer;


void setup() {
  //formaat van de sketch
  size(640, 360); 
  noStroke();  
  
  //particle systeem word aangemaakt in het midden van het scherm
  ps = new ParticleSystem(new PVector(width/2, height/2));
  
  //de kleur van de bubbels wordt op 0 gezet bij het starten van de sketch
 bubbleColor = 0;
  
  //check of de kinect is verbonden zo niet wordt de sketch afgesloten
  context = new SimpleOpenNI(this);
  if(context.isInit() == false)
  {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }   

  // aanzetten depthMap generation 
  context.enableDepth();
  
  // spiegelen uitzetten
  context.setMirror(true);

  // toestaan van hand en gesture herkenning
  context.enableHand();
  context.startGesture(SimpleOpenNI.GESTURE_WAVE);
  context.startGesture(SimpleOpenNI.GESTURE_CLICK);
   
   //audio input
   input = new AudioIn(this, 0);

  // start de Audio Input
  input.start();

  // Maak een nieuwe Amplitude analyzer
  analyzer = new Amplitude(this);

  // verwerk de input in een volume analyzer
  analyzer.input(input);
}

void draw() { 
  //background color
  background(bg);
  

 
// volg de muis met een kleine delay
  float targetX = mouseX;
  float dx = targetX - x;
  x += dx * easing;
  
  float targetY = mouseY;
  float dy = targetY - y;
  y += dy * easing;
  
  PVector mouseFollow = new PVector(x,y);
   
   ///////mouse particle follow
   //ps.addParticle(mouseFollow, 3);
   ellipse(x, y, 20, 20);
  
  ///////particle systeem om kleur te testen
  //PVector center = new PVector(width/2, height/2);
  //ps.addParticle(center, bubbleColor);
  
  // start particle systeem
  ps.run();
  
  //////verander achtergrond kleur op basis van de muis positie
 // bg = color(0 + mouseY / 10,0,0 + mouseX / 10); 
  
  // update kinect
  context.update();
   
   //laat hand positie zien op het scherm wanneer er een hand is gedetecteerd
     if(handPathList.size() > 0)  
  {    
    Iterator itr = handPathList.entrySet().iterator();     
    while(itr.hasNext())
    {
      Map.Entry mapEntry = (Map.Entry)itr.next(); 
      int handId =  (Integer)mapEntry.getKey();
      ArrayList<PVector> vecList = (ArrayList<PVector>)mapEntry.getValue();
      PVector p;
      PVector p2d = new PVector();
           
        Iterator itrVec = vecList.iterator(); 
          while( itrVec.hasNext() ) 
          { 
            p = (PVector) itrVec.next(); 
            // converteer de kinect coordinaten naar het scherm
            context.convertRealWorldToProjective(p,p2d);
            vertex(p2d.x,p2d.y);
            
          }
        p = vecList.get(0);
        context.convertRealWorldToProjective(p,p2d);
        point(p2d.x,p2d.y);
 
  //berekend hand positie ten opzicht van het midden van het scherm
  float d = dist(width/2, height/2, p2d.x, p2d.y);
  distance = d;
  // ellipse om de handpositie zichtbaar te maken 
  ellipse(p2d.x, p2d.y, 20, 20);
 
 
   //particle systeem volgt de hand positie en wanneer het volume hoog genoeg is spawnen er particles op de hand positie
        float vol = analyzer.analyze();
        if (vol > 0.15){
        ps.addParticle(p2d, bubbleColor);
        }
   //wanneer de hand onder aan het scherm is kan de kleur van de bubbels veranderd worden afhankelijk van welke x positie zijn er 6 kleuren mogelijk
        if (p2d.y > 300){
          if(p2d.x < 107){
          bubbleColor = 0;
          }else if(p2d.x > 107 && p2d.x < 214){
            bubbleColor = 1;
          }else if(p2d.x > 214 && p2d.x < 321){
            bubbleColor = 2;
          }else if(p2d.x > 321 && p2d.x < 428){
            bubbleColor = 3;
          }else if(p2d.x > 428 && p2d.x < 535){
            bubbleColor = 4;
          }else if(p2d.x > 535 && p2d.x < 640){
            bubbleColor = 5;
          }
        }
      }        
    }
  
}


// particle systeem class
class ParticleSystem {
  //alle particles worden opgeslagen in een list
  ArrayList<Particle> particles;
  PVector origin;

  ParticleSystem(PVector position) {
    origin = position.copy();
    particles = new ArrayList<Particle>();
  }

//particles toeveogen aan de list om te spawnen met een bepaalde kleur en positie van de hand
  void addParticle(PVector mouse, int colnum) {
    particles.add(new Particle(mouse, colnum ));
    
  }

//particles spawnen en niet meer nodige particles verwijderen
  void run() {
     
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.run();
      if (p.isDead()) {
        particles.remove(i);
      }
    } 
  }

}


//Particle class

class Particle {
  //particle variable
  PVector position;
  PVector velocity;
  PVector acceleration;
  float lifespan;
  int Colnum;
  
// levensduur en bewegingsrichting van de bubbels
  Particle(PVector l ,int colnum) {
    acceleration = new PVector( 0 , -0.05 );
    velocity = new PVector(random(-4, 4), random(-1, -5));
    position = l.copy();
    lifespan = 255.0;
    Colnum = colnum;
  }

//update particle
  void run() {
    update();
    display();
  
  }

  // positie van bubbles updaten en levensduur
  void update() {
    velocity.add(acceleration);
    position.add(velocity);
    lifespan -= 2.0;
  }

  // visueel maken van de particle
  void display() {
  // array met mogelijke kleuren
    color[] bubbleColor = new color[]{
    color(255-lifespan,0+lifespan,0+lifespan*2,80), // blue
    color(255-lifespan,255-lifespan,0+lifespan*2,80), //darkblue
    color(0+lifespan,255-lifespan,0+lifespan*2,80), //pink
    color(0+lifespan*2,0+lifespan,255-lifespan,80), //yellow
    color(0+lifespan*2,255-lifespan,255-lifespan,80), // red
    color(0+lifespan,0+lifespan*2,0+lifespan,80) //green
    };
    
    noStroke();
    // bubbel kleur toewijzen
    fill(bubbleColor[Colnum]);
    //formaat van de bubbels
    ellipse(position.x, position.y, distance / 7, distance / 7);
  }

  // check of de bubbel nog bruikbaar is en anders laten verdwijnen
  boolean isDead() {
    if (lifespan < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}

// detecteer hand en aan list toevoegen
void onNewHand(SimpleOpenNI curContext,int handId,PVector pos)
{
  println("onNewHand - handId: " + handId + ", pos: " + pos);
 
  ArrayList<PVector> vecList = new ArrayList<PVector>();
  vecList.add(pos);
  
  handPathList.put(handId,vecList);
}
// update hand wanneer gedetecteerd
void onTrackedHand(SimpleOpenNI curContext,int handId,PVector pos)
{

  ArrayList<PVector> vecList = handPathList.get(handId);
  
  if(vecList != null)
  {
    vecList.add(0,pos);
    if(vecList.size() >= handVecListSize)
      // laatste punt verwijderen 
      vecList.remove(vecList.size()-1); 
  }  
}
// verwijder hand wanneer niet meer zichtbaar
void onLostHand(SimpleOpenNI curContext,int handId)
{
  println("onLostHand - handId: " + handId);
  handPathList.remove(handId);
}

// -----------------------------------------------------------------
// wanneer een gesture wordt voltooid

void onCompletedGesture(SimpleOpenNI curContext,int gestureType, PVector pos)
{
  println("onCompletedGesture - gestureType: " + gestureType + ", pos: " + pos);
  
  int handId = context.startTrackingHand(pos);
  println("hand stracked: " + handId);
  

}
