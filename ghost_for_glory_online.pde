/* @pjs preload="blue_ghost.png",
"cave32.png",
"hero.png",
"leaderboard.csv",
"overworld32.png",
"sorcerer.png",
"white_ghost.png"; 
*/

gamemanager gm;
int millis;

void settings()
{
  size(WIDTH, HEIGHT);
}

void setup()
{
  gm = new gamemanager();
  gm.setKeyBinds('a', 'd', 'w', 's');
  
  gm.reset();
}

void draw()
{
  background(0);
  gm.executeCommands();
  gm.display();
}

void keyPressed()
{
  gm.pressedKey(key);
}

class character
{
  //display variables
  protected float posX; //getter
  protected float posY; //getter
  protected float displayPosX;
  protected float displayPosY;

  
  protected PImage spritesheet;
  protected int frame;
  
  protected direction dir;
  protected float spriteTime; //milliseconds
  protected int lastTick;
  
  //dying variables
  protected boolean isAlive;
  protected float dyingAnimationTime;
  protected particlesystem ps;
  
  //shooting variables
  protected ArrayList<shot> shots;
  protected float shotTime; //cooldown time before next shot
  protected float shotDistance; //shot distance in pixels
  protected int lastShot; //last shot time
  protected int malusStart;

  
  //stats
  protected float malusCooldown;
  protected boolean hasMalus;
  protected float life;
  protected float speed;
  protected float initialSpeed;
  
  
  character(PImage spritesheet, float posX, float posY)
  {
    this.posX = posX;
    this.posY = posY;
    this.displayPosX = posX;
    this.displayPosY = posY;
    this.spritesheet = spritesheet;
    this.spritesheet = spritesheet;
    spriteTime = 100;
    frame = 0;
    isAlive = true;
    lastTick = millis();
    shots = new ArrayList<shot>();
    lastShot = 0;
    this.malusCooldown = MALUS_DURATION;
    this.hasMalus = false;
  }
  
  void die()
  {
    isAlive = false;
    life = 0;
    ps = new particlesystem(new PVector(posX + (TILESIZE / 2), posY + (TILESIZE / 2)));
    for (int i = 0; i < 20; i++)
      ps.addParticle();
    shots.clear();  
  }
  
  void applyEffects(shot s)
  {
    life -= s.getDamage();
    if (s.getSpeedMalus() > 0 && !hasMalus)
    {
      speed -= s.getSpeedMalus();
      hasMalus = true;
      malusStart = millis;
    }
  }
  
  void updateMaluses()
  {
    if (hasMalus)
    {
      int delta = millis - malusStart;
      if (delta * 0.001 >= malusCooldown)
      {
        speed = initialSpeed;
        hasMalus = false;
      }
    }
  }
  
  boolean checkCollision(float x, float y)
  {
    if (isAlive)
    {
      return ( (x >= posX) && (x <= posX + TILESIZE) && (y >= posY) && (y <= posY + TILESIZE) );
    }
    else
      return false;
  }
  
  void update(direction dir, float movement)
  {
    if (isAlive)
    {   
      int delta = millis - lastTick;
      if (delta >= spriteTime)
      {
        frame = (frame + 1) % NUMSPRITES;
        lastTick += delta;
      }
      this.dir = dir;
      if (dir == direction.DIR_DOWN)
      {
        posY += movement;
      }
      else if (dir == direction.DIR_LEFT)
      {
        posX -= movement;
      }
      else if (dir == direction.DIR_RIGHT)
      {
        posX += movement;
      }
      else if (dir == direction.DIR_UP)
      {
        posY -= movement;
      }
      else
        posX = 0;
    }
    else
    {
      ps.update();
    }
  }
  
  boolean canShoot()
  {
    int delta = millis - lastShot;
    if (delta * 0.001 >= shotTime)
      return true;
    else 
      return false;
  }
  
  
  shot addShot(ArrayList<? extends character> targets)
  {
    float shotX = posX + (TILESIZE / 2);
    float shotY = posY + (TILESIZE / 2);
    float targetX;
    float targetY;
    PVector min_ray = new PVector(Float.MAX_VALUE, Float.MAX_VALUE);
    PVector ray;
    shot s = null;
    for (character c : targets)
    {
      if (c.getIsAlive() == false)
        continue;
      targetX = c.getPosX() + (TILESIZE / 2);
      targetY = c.getPosY() + (TILESIZE / 2);
      ray = new PVector(targetX - shotX, targetY - shotY);
      if (ray.mag() <= shotDistance && ray.mag() < min_ray.mag())
      {
        s = new shot(shotX, shotY);
        s.setShotDirection(ray.normalize());
        shots.add(s);
        lastShot = millis;
        min_ray = ray.copy();
      }
    }
    return s;  
  }
  
  boolean isDying()
  {
    return ps.isExploding();
  }
  
  void display()
  {
    if (isAlive)
    {
      PImage f;
      if (dir == direction.DIR_DOWN)
        f = spritesheet.get(frame * TILESIZE, TILESIZE * 0, TILESIZE, TILESIZE);
      else if (dir == direction.DIR_LEFT)
        f = spritesheet.get(frame * TILESIZE, TILESIZE * 1, TILESIZE, TILESIZE);
      else if (dir == direction.DIR_RIGHT)
        f = spritesheet.get(frame * TILESIZE, TILESIZE * 2, TILESIZE, TILESIZE);
      else if (dir == direction.DIR_UP)
        f = spritesheet.get(frame * TILESIZE, TILESIZE * 3, TILESIZE, TILESIZE);
      else
        f = spritesheet.get(-1, -1, TILESIZE, TILESIZE);
      
      image(f, displayPosX, displayPosY);
    }
    else
    {
      ps.display();
    }
  }
  
  
  float getPosX()
  {
    return posX;
  }
  
  float getPosY()
  {
    return posY;
  }
  
  direction getDir()
  {
    return dir;
  }
  
  ArrayList<shot> getShots()
  {
    return shots;
  }
  
  float getLife()
  {
    return life;
  }
  
  boolean getIsAlive()
  {
    return isAlive;
  }
  
  float getSpeed()
  {
    return speed;
  }
  
  void setOffset(float offsetX, float offsetY)
  {
    if (isAlive)
    {
      displayPosX = posX + offsetX;
      displayPosY = posY + offsetY;
    }
    else
    {
      ps.setOffset(new PVector(offsetX, offsetY));
    }
  }
  
  void setOffsetX(float offsetX)
  {
    if (isAlive)
    {
      displayPosX = posX + offsetX;
    }
    else
      ps.setOffset(new PVector(offsetX, 0));
    
  }
  
  void setOffsetY(float offsetY)
  {
    if (isAlive)
    {
      displayPosY = posY + offsetY;
    }
    else
      ps.setOffset(new PVector(0, offsetY));
  }
  
}

//general
enum gamestate {START, WAITING, GAME, GAMEOVER, INSERT_NAME, ENDGAME};
String TITLE = "GHOSTS FOR GLORY";
float BLINKING_TIME = 1;
color TEXT_COLOR = color(255);

//leaderboard
String NAME_HEADER = "Name";
String SCORE_HEADER = "Score";
String LEADERBOARD_FILE = "leaderboard.csv";

//tiles
int STARTASCII = 46;
String OVERWORLD = "overworld32.png";
String CAVE = "cave32.png";
color HL_COLOR = color(255, 0, 0);  //debug

int TILESIZE = 32;//32;

//levels
int TOTALHORIZONTALTILES = 30;
int TOTALVERTICALTILES = 30;
enum layer {BACKGROUND, OBSTACLES};
enum levelName {LEVEL1, LEVEL2, LEVEL3, LEVEL4};
String LEVEL1_BG = "level1_background.csv";
String LEVEL1_O = "level1_obstacles.csv";
String LEVEL2_BG = "level2_background.csv";
String LEVEL2_O = "level2_obstacles.csv";
String LEVEL3_BG = "level3_background.csv";
String LEVEL3_O = "level3_obstacles.csv";
String LEVEL4_BG = "level4_background.csv";
String LEVEL4_O = "level4_obstacles.csv";

int POINTS_LEVEL1 = 10;
int POINTS_LEVEL2 = 25;
int POINTS_LEVEL3 = 40;
int POINTS_LEVEL4 = 60;

//character
enum heroes {HERO1} //in case one wants to add more heroes
enum enemies {WGHOST, BGHOST, SORCERER}

int POINTS_WGHOST = 2;
int POINTS_BGHOST = 5;
int POINTS_SORCERER = 15;

float MALUS_DURATION = 5;

float SPAWN_TIME_WGHOST = 1;
float SPAWN_TIME_BGHOST = 5;
float SPAWN_TIME_SORCERER = 10;

float LIFE_PLAYER = 10;
float LIFE_WGHOST = 1;
float LIFE_BGHOST = 2;
float LIFE_SORCERER = 4;

//time in seconds
float CHANGE_DIR_TIME_WGHOST = 2;
float CHANGE_DIR_TIME_BGHOST = 4;
float CHANGE_DIR_TIME_SORCERER = 3;

//speed in pixels
float SPEED_PLAYER = 100;
float SPEED_WGHOST = 50;
float SPEED_BGHOST = 120;
float SPEED_SORCERER = 90;

//distance in pixels
float SHOT_PLAYER_DISTANCE = 200;
float SHOT_BGHOST_DISTANCE = 300;
float SHOT_SORCERER_DISTANCE = 200;

//time in seconds
float SHOT_PLAYER_COOLDOWN = 1;
float SHOT_BGHOST_COOLDOWN = 4;
float SHOT_SORCERER_COOLDOWN = 3;

color SHOT_PLAYER_COLOR = color(200);
color SHOT_BGHOST_COLOR = color(100, 100, 250);
color SHOT_SORCERER_COLOR = color(150, 0, 150);

//speed in pixels
float SHOT_PLAYER_SPEED = 200;
float SHOT_BGHOST_SPEED = 70;
float SHOT_SORCERER_SPEED = 110;

float SHOT_PLAYER_DAMAGE = 1;
float SHOT_BGHOST_DAMAGE = 0;
float SHOT_SORCERER_DAMAGE = 2;

//speed in pixels
float SHOT_PLAYER_SPEEDMALUS = 0;
float SHOT_BGHOST_SPEEDMALUS = 50;
float SHOT_SORCERER_SPEEDMALUS = 0;

//dim in pixels
float SHOT_DIMENSION = 10;

int NUMSPRITES = 3;
enum direction {DIR_UP, DIR_DOWN, DIR_LEFT, DIR_RIGHT}
String HERO1 = "hero.png";
String WGHOST = "white_ghost.png";
String BGHOST = "blue_ghost.png";
String SORCERER = "sorcerer.png";

//sizes
int VERTICALTILES = 15;
int HORIZONTALTILES = 15;
int INFOBARSIZE = TILESIZE;
int WIDTH = HORIZONTALTILES * TILESIZE; //480;
int HEIGHT = VERTICALTILES * TILESIZE; //480;

class enemy extends character
{
  private enemies enemytype;
  private float changeDirTime;
  private int dirTick;
  private int speedTick;
  private int pointsValue;
  
  
  
  enemy(PImage spritesheet, float posX, float posY, enemies enemytype)
  {
    
    super(spritesheet, posX, posY);
    this.enemytype = enemytype;
    dir = changeDirectionImmediate();
    dirTick = millis();
    speedTick = dirTick;
    if (enemytype == enemies.WGHOST)
    {
      changeDirTime = CHANGE_DIR_TIME_WGHOST;
      speed = SPEED_WGHOST;
      initialSpeed = speed;
      life = LIFE_WGHOST;
      pointsValue = POINTS_WGHOST;
    }
    else if (enemytype == enemies.BGHOST)
    {
      changeDirTime = CHANGE_DIR_TIME_BGHOST;
      speed = SPEED_BGHOST;
      initialSpeed = speed;
      life = LIFE_BGHOST;
      shotTime = SHOT_BGHOST_COOLDOWN;
      shotDistance = SHOT_BGHOST_DISTANCE;
      pointsValue = POINTS_BGHOST;
    }
    else if (enemytype == enemies.SORCERER)
    {
      changeDirTime = CHANGE_DIR_TIME_SORCERER;
      speed = SPEED_SORCERER;
      initialSpeed = speed;
      life = LIFE_SORCERER;
      shotTime = SHOT_SORCERER_COOLDOWN;
      shotDistance = SHOT_SORCERER_DISTANCE;
      pointsValue = POINTS_SORCERER;
    }
    
  }
  
  shot addShot(ArrayList<? extends character> targets)
  {
    if (enemytype == enemies.WGHOST)
      return null;
    shot s = super.addShot(targets);
    if (s != null)
    {
      if (enemytype == enemies.BGHOST)
      {
        s.setSpeed(SHOT_BGHOST_SPEED);
        s.setDamage(SHOT_BGHOST_DAMAGE);
        s.setColor(SHOT_BGHOST_COLOR);
        s.setSpeedMalus(SHOT_BGHOST_SPEEDMALUS);
      }
      else if (enemytype == enemies.SORCERER)
      {
        s.setSpeed(SHOT_SORCERER_SPEED);
        s.setDamage(SHOT_SORCERER_DAMAGE);
        s.setColor(SHOT_SORCERER_COLOR);
        s.setSpeedMalus(SHOT_SORCERER_SPEEDMALUS);
      }
      
    }
    return s;
  }
  
  direction changeDirection()
  {
    int delta = millis - dirTick;
    if (delta * 0.001 >= changeDirTime)
    {
      dirTick += delta;
      return changeDirectionImmediate();
    }
    else
      return dir;
  }
  
  float calculateMovement()
  {
    int delta = millis - speedTick;
    speedTick += delta;
    return speed * delta * 0.001;
  }
  
  
  direction changeDirectionImmediate()
  {
    direction[] dirs = {direction.DIR_UP, direction.DIR_DOWN, direction.DIR_LEFT, direction.DIR_RIGHT};
    return dirs[int(random(dirs.length))];
  }
  
  enemies getEnemyType()
  {
    return enemytype;
  }
  
  int getPointsValue()
  {
    return pointsValue;
  }
  
}

class enemyspawner
{

  ArrayList<enemy> enemyList; //getter
  levelName lvl;
  float spawnTime_wghost;
  float spawnTime_bghost;
  float spawnTime_sorcerer;
  int maxEnemies;
  int lastSpawn_wghost;
  int lastSpawn_bghost;
  int lastSpawn_sorcerer;
  
  enemyspawner(levelName lvl)
  {
    this.lvl = lvl;
    lastSpawn_wghost = millis();
    lastSpawn_bghost = lastSpawn_wghost;
    lastSpawn_sorcerer = lastSpawn_wghost;
  }
  
  
  void initEnemies()
  {
    enemyList = new ArrayList<enemy>();
    if (lvl == levelName.LEVEL1)
    {
      spawnTime_wghost = SPAWN_TIME_WGHOST;
      spawnTime_bghost = SPAWN_TIME_BGHOST;
      spawnTime_sorcerer = SPAWN_TIME_SORCERER;
      maxEnemies = 5;
    }
    else if (lvl == levelName.LEVEL2)
    {
      spawnTime_wghost = SPAWN_TIME_WGHOST;
      spawnTime_bghost = SPAWN_TIME_BGHOST;
      spawnTime_sorcerer = SPAWN_TIME_SORCERER;
      maxEnemies = 8;
    }
    else if (lvl == levelName.LEVEL3)
    {
      spawnTime_wghost = SPAWN_TIME_WGHOST;
      spawnTime_bghost = SPAWN_TIME_BGHOST;
      spawnTime_sorcerer = SPAWN_TIME_SORCERER;
      maxEnemies = 8;
    }
    else if (lvl == levelName.LEVEL4)
    {
      spawnTime_wghost = SPAWN_TIME_WGHOST;
      spawnTime_bghost = SPAWN_TIME_BGHOST;
      spawnTime_sorcerer = SPAWN_TIME_SORCERER;
      maxEnemies = 15;
    }
  }
  
  void spawnEnemy(level obstacles, float playerX, float playerY)
  {
      ArrayList<Integer> availableTiles = new ArrayList<Integer>();
      for (tile t : obstacles.getTiles())
      {
        if (t.getType() == -1)
          availableTiles.add(t.getTileNumber());
      }
      int selectedTile = int(random(availableTiles.size()));

      boolean isColl = true;
      while ( isColl )
      {
        if ( obstacles.isColliding(availableTiles.get(selectedTile), playerX, playerY, false) ||
              obstacles.isColliding(availableTiles.get(selectedTile), playerX, playerY - TILESIZE, false) ||
              obstacles.isColliding(availableTiles.get(selectedTile), playerX + TILESIZE, playerY - TILESIZE, false) ||
              obstacles.isColliding(availableTiles.get(selectedTile), playerX + TILESIZE, playerY, false) ||
              obstacles.isColliding(availableTiles.get(selectedTile), playerX + TILESIZE, playerY + TILESIZE, false) ||
              obstacles.isColliding(availableTiles.get(selectedTile), playerX, playerY + TILESIZE, false) ||
              obstacles.isColliding(availableTiles.get(selectedTile), playerX - TILESIZE, playerY + TILESIZE, false) ||
              obstacles.isColliding(availableTiles.get(selectedTile), playerX - TILESIZE, playerY, false) ||
              obstacles.isColliding(availableTiles.get(selectedTile), playerX - TILESIZE, playerY - TILESIZE, false) )
              {
                selectedTile = int(random(availableTiles.size()));
                isColl = true;
              }
         else
         {
           isColl = false;
         }
      }
      tile[] tiles = obstacles.getTiles();
      float posX = tiles[availableTiles.get(selectedTile)].getPosX();
      float posY = tiles[availableTiles.get(selectedTile)].getPosY();
      enemies enemytype = selectEnemyType();
      PImage spritesheet = null;
      if (enemytype == enemies.WGHOST)
      {
        spritesheet = loadImage(WGHOST);
        lastSpawn_wghost = millis;
      }
      else if (enemytype == enemies.BGHOST)
      {
        spritesheet = loadImage(BGHOST);
        lastSpawn_bghost = millis;
      }
      else if (enemytype == enemies.SORCERER)
      {
        spritesheet = loadImage(SORCERER);
        lastSpawn_sorcerer = millis;
      }
      enemyList.add(new enemy(spritesheet, posX, posY, enemytype));
  }

  //returns true the moment an enemy is killed
  boolean checkKilling(int pos)
  {
    if (enemyList.get(pos).getLife() > 0)
    {
      return false;
    }
    
    if (enemyList.get(pos).getEnemyType() == enemies.WGHOST)
      lastSpawn_wghost = millis;
    else if (enemyList.get(pos).getEnemyType() == enemies.BGHOST)
      lastSpawn_bghost = millis;
    else if (enemyList.get(pos).getEnemyType() == enemies.SORCERER)
      lastSpawn_sorcerer = millis;
      
    if (enemyList.get(pos).getIsAlive() == true)
    {
      enemyList.get(pos).die();
      return true;
    }
    else if (enemyList.get(pos).isDying() == false)
    {
      enemyList.remove(pos);
    }
    return false;
  }

  boolean canSpawn()
  {
    if (enemyList.size() >= maxEnemies)
      return false;
    if ( ((millis - lastSpawn_sorcerer) * 0.001 >= spawnTime_sorcerer) ||
         ((millis - lastSpawn_bghost) * 0.001 >= spawnTime_bghost) ||
         ((millis - lastSpawn_wghost) * 0.001 >= spawnTime_wghost) )
      return true;
    return false;
  }

  //assumes there's an enemy to spawn
  enemies selectEnemyType()
  {
    if ((millis - lastSpawn_sorcerer) * 0.001 >= spawnTime_sorcerer)
    {
      return enemies.SORCERER;
    }
    else if ((millis - lastSpawn_bghost) * 0.001 >= spawnTime_bghost)
    {
      return enemies.BGHOST;
    }
    else
    {
      return enemies.WGHOST;
    }
  }
  
  ArrayList<enemy> getEnemyList()
  {
    return enemyList;
  }
  
}

//game manager class

class gamemanager
{
  //the background of the level
  private level currentlevel_bg; //getter
  //the obstacles in the level
  private level currentlevel_o; //getter
  
  //variables to access the player character and the enemies
  private enemyspawner spawner;
  private player player1;
  
  //describes the "moment" of the game
  gamestate state;
    
  //variables for movement
  private char leftMovement;
  private char rightMovement;
  private char upMovement;
  private char downMovement;
  private boolean isLeft;
  private boolean isRight;
  private boolean isUp;
  private boolean isDown;

  private float offsetX; //setter
  private float offsetY; //setter
  
  private int lastTick;
  
  //UI elements
  //last tick for blinking UI elements
  private int lastTickBlinking;
  private boolean enterKey;
  private hiscore playerScore;
  private leaderboard leaderBoard;
  private int levelNumber;
  
  gamemanager()
  {
    lastTick = millis(); //probably this should be initialized when the game actually starts
    lastTickBlinking = lastTick;
    enterKey = false;
    leaderBoard = new leaderboard(LEADERBOARD_FILE);
    setState(gamestate.START);
  }
  
  //reset variables, necessary before loading a new level
  void reset()
  {
    offsetX = 0;
    offsetY = 0;
    this.isUp = false;
    this.isDown = false;
    this.isLeft = false;
    this.isRight = false;
    this.currentlevel_bg = null;
    this.currentlevel_o = null;
    this.spawner = null;
    player1 = null;
    playerScore = null;
    levelNumber = 0;
  }
  
  //method called when a new level must be loaded
  void startGame()
  {
    if (playerScore == null)
      playerScore = new hiscore();
    if (levelNumber == 1)
    {
      initLevel(levelName.LEVEL1);
      spawner = new enemyspawner(levelName.LEVEL1);
    }
    else if (levelNumber == 2)
    {
      initLevel(levelName.LEVEL2);
      spawner = new enemyspawner(levelName.LEVEL2);
    }
    else if (levelNumber == 3)
    {
      initLevel(levelName.LEVEL3);
      spawner = new enemyspawner(levelName.LEVEL3);
    }
    else if (levelNumber == 4)
    {
      initLevel(levelName.LEVEL4);
      spawner = new enemyspawner(levelName.LEVEL4);
    }
    
    initPlayer(heroes.HERO1);
    spawner.initEnemies();
    isUp = true;
    lastTick = millis(); //is this good here?
  }
  
  void setKeyBinds(char leftMovement, char rightMovement, char upMovement, char downMovement)
  {
    this.leftMovement = leftMovement;
    this.rightMovement = rightMovement;
    this.upMovement = upMovement;
    this.downMovement = downMovement;
  }
  
  void initLevel(levelName ln)
  {
    currentlevel_bg = new level(layer.BACKGROUND);
    currentlevel_o = new level(layer.OBSTACLES);
    if (ln == levelName.LEVEL1)
    {
      loadLevel(LEVEL1_BG, layer.BACKGROUND, currentlevel_bg, OVERWORLD);
      loadLevel(LEVEL1_O, layer.OBSTACLES, currentlevel_o, OVERWORLD);
    }
    else if (ln == levelName.LEVEL2)
    {
      loadLevel(LEVEL2_BG, layer.BACKGROUND, currentlevel_bg, CAVE);
      loadLevel(LEVEL2_O, layer.OBSTACLES, currentlevel_o, CAVE);
    }
    else if (ln == levelName.LEVEL3)
    {
      loadLevel(LEVEL3_BG, layer.BACKGROUND, currentlevel_bg, OVERWORLD);
      loadLevel(LEVEL3_O, layer.OBSTACLES, currentlevel_o, OVERWORLD);
    }
    else if (ln == levelName.LEVEL4)
    {
      loadLevel(LEVEL4_BG, layer.BACKGROUND, currentlevel_bg, OVERWORLD);
      loadLevel(LEVEL4_O, layer.OBSTACLES, currentlevel_o, OVERWORLD);
    }
    //display the center of the level
    offsetX = ((TOTALHORIZONTALTILES * 0.5) * TILESIZE) - ((WIDTH) * 0.5); 
    offsetY = ((TOTALVERTICALTILES * 0.5) * TILESIZE) - ((HEIGHT) * 0.5);
  }
  
  void initPlayer(heroes hero)
  {
    if (hero == heroes.HERO1)
    {
      PImage sprite = loadImage(HERO1);

      player1 = new player(sprite, (TOTALHORIZONTALTILES * 0.5) * TILESIZE, (TOTALVERTICALTILES * 0.5) * TILESIZE, hero);

      player1.setOffsetX(-1 * offsetX);
      player1.setOffsetY(-1 * offsetY);
    }
  }
  
  
  
  
  
  void loadLevel(String lev, layer l, level lv, String tileFile)
  {
    if (lv.getTilesLayer() != l)
      return;
    PImage tilesheet = loadImage(tileFile);
    lv.init(lev, tilesheet);
  }
  
  //check if the given character is colliding with enemies
  boolean checkCollisionsWithEnemies(character c)
  {
    float x = c.getPosX();
    float y = c.getPosY();
    for (enemy e : spawner.getEnemyList())
    {
      if (e.checkCollision(x, y))
        return true;
      else if (e.checkCollision(x + TILESIZE - 1, y))
        return true;
      else if (e.checkCollision(x + TILESIZE - 1, y + TILESIZE - 1))
        return true;
      else if (e.checkCollision(x, y + TILESIZE - 1))
        return true;
    }
    return false;
  }
  
  //check if the given character is colliding with the level's obstacles
  boolean checkCollisionsWithLevel(character c)
  {
    float x = c.getPosX();
    float y = c.getPosY();
    int tileX = int(x) / TILESIZE;
    int tileY = int(y) / TILESIZE;
    int tileToCheck = tileY + (tileX * TOTALVERTICALTILES);
    if (c.getDir() == direction.DIR_UP)
    {
      //currentlevel_o.highlight(tileToCheck); //debug
      //currentlevel_o.highlight(tileToCheck + TOTALVERTICALTILES); //debug
      if (currentlevel_o.isColliding(tileToCheck, x, y, true) ||
          currentlevel_o.isColliding(tileToCheck + TOTALVERTICALTILES, x + TILESIZE - 1, y, true))
          {
            return true;
          }
    }
    else if (c.getDir() == direction.DIR_DOWN)
    {
      //currentlevel_o.highlight(tileToCheck + 1); //debug
      //currentlevel_o.highlight(tileToCheck + TOTALVERTICALTILES + 1); //debug
      if (currentlevel_o.isColliding(tileToCheck + 1, x, y + TILESIZE, true) ||
          currentlevel_o.isColliding(tileToCheck + TOTALVERTICALTILES + 1, x + TILESIZE - 1, y + TILESIZE - 1, true))
          {
            return true;
          }
      
    }
    else if (c.getDir() == direction.DIR_RIGHT)
    {
      //currentlevel_o.highlight(tileToCheck + TOTALVERTICALTILES); //debug
      //currentlevel_o.highlight(tileToCheck + TOTALVERTICALTILES + 1); //debug
      if (currentlevel_o.isColliding(tileToCheck + TOTALVERTICALTILES, x + TILESIZE - 1, y, true) ||
          currentlevel_o.isColliding(tileToCheck + TOTALVERTICALTILES + 1, x + TILESIZE - 1, y + TILESIZE - 1, true))
          {
            return true;
          }
          
    }
    else if (c.getDir() == direction.DIR_LEFT)
    {
      //currentlevel_o.highlight(tileToCheck); //debug
      //currentlevel_o.highlight(tileToCheck + 1); //debug
      if (currentlevel_o.isColliding(tileToCheck, x, y, true) ||
          currentlevel_o.isColliding(tileToCheck + 1, x, y + TILESIZE, true))
          {
            return true;
          }
    }
    return false;
  }
  
  //move the character according to the last input
  void move()
  {
    //should avoid movement if game has not yet started
    float delta = millis - lastTick;
    float deltaSeconds = delta * 0.001;
    direction d = direction.DIR_UP;
    if (state == gamestate.GAME)
    {
      if (isLeft)
      {
        offsetX -= (player1.getSpeed() * deltaSeconds);
        d = direction.DIR_LEFT;
      }
      if (isRight)
      {
        offsetX += (player1.getSpeed() * deltaSeconds);
        d = direction.DIR_RIGHT;
      }
      if (isUp)
      {  
        offsetY -= (player1.getSpeed() * deltaSeconds);
        d = direction.DIR_UP;
      }
      if (isDown)
      {
        offsetY += (player1.getSpeed() * deltaSeconds);
        d = direction.DIR_DOWN;
      }
    }
    player1.update(d, player1.getSpeed() * deltaSeconds);
    
    lastTick += delta;
  }
  
  //move the enemies
  void movenemies()
  {
    for (enemy e : spawner.getEnemyList())
      {
        //check in which direction the enemy should move
        direction d = e.changeDirection();
        //calculate the displacement of the enemy
        float movement = e.calculateMovement();
        //update the position of the enemy
        e.update(d, movement);

        //check if in the new position the enemy would collide with level
        //if there is a collision, move again the enemy to its previous position,
        //change its direction randomly and move it again
        //repeat until there are no collision
        while (checkCollisionsWithLevel(e))
        {
          if (d == direction.DIR_LEFT)
          {
            e.update(direction.DIR_RIGHT, movement);
          }
          else if (d == direction.DIR_RIGHT)
          {
            e.update(direction.DIR_LEFT, movement);
          }
          else if (d == direction.DIR_UP)
          {
            e.update(direction.DIR_DOWN, movement);
          }
          else if (d == direction.DIR_DOWN)
          {
            e.update(direction.DIR_UP, movement);
          }
          d = e.changeDirectionImmediate();
          e.update(d, movement);
        }
      }
  }

  void setEnemiesOffset()
  {
    for (enemy e : spawner.getEnemyList())
    {
      e.setOffset(-1 * offsetX, -1 * offsetY);
    }
  }
  
  void setPlayerOffset()
  {
    player1.setOffset(-1 * offsetX, -1 * offsetY);
  }
  
  void setShotsOffset()
  {
    for (shot s : player1.getShots())
        s.setOffset(-1 * offsetX, -1 * offsetY);
    for (enemy e : spawner.getEnemyList())
    {
      for (shot s : e.getShots())
        s.setOffset(-1 * offsetX, -1 * offsetY);
    }
  }
  
  
  
  void pressedKey(char c)
  {
    if (state == gamestate.GAME)
    {
      //set the new direction according to the pressed key
      //the character cannot go on the direction opposite to the current one
      if ((c == leftMovement && isRight) ||
          (c == rightMovement && isLeft) ||
          (c == upMovement && isDown) ||
          (c == downMovement && isUp) ||
          ((c != leftMovement) &&
           (c != rightMovement) &&
           (c != upMovement) &&
           (c != downMovement)) )
          return;
      isLeft = (c == leftMovement);
      isRight = (c == rightMovement);
      isUp = (c == upMovement);
      isDown = (c == downMovement);
    }
    else if ((state == gamestate.GAMEOVER) && player1.isDying())
    {
      return;
    }
    else if (state == gamestate.INSERT_NAME)
    {
      //use keys to write the name for the hiscore
      String name = playerScore.getName();
      if (((int(c) >= 65) && (int(c) <= 122)) ||
          ((int(c) >= 48) && (int(c) <= 57)))
      {
        name += c;    
      }
      else if (int(c) == 8) //BACKSPACE
      {
        String enterTemp = "";
        for (int i = 0; i < name.length() - 1; i++)  //copy all chars except the last one
        {
          enterTemp += name.charAt(i);
        }
        name = enterTemp;
      }
      else if (int(c) == 10) //ENTER
      {
        enterKey = true;
      }
      playerScore.setName(name);
    }
    else if (int(c) == 10) //if press ENTER in any other game state
    {
      enterKey = true;
    }
    
  }

  //check if the level has been completed to proceed to the next level
  void checkNextLevel()
  {
    //the app support variable is needed because the reset() function actually resets the playerscore variable
    if (levelNumber == 1 && (playerScore.getScore() >= POINTS_LEVEL1))
    {
      hiscore app = playerScore;
      reset();
      state = gamestate.WAITING;
      playerScore = app;
      levelNumber = 1;
    }
    else if (levelNumber == 2 && (playerScore.getScore() >= POINTS_LEVEL2))
    {
      hiscore app = playerScore;
      reset();
      state = gamestate.WAITING;
      playerScore = app;

      levelNumber = 2;
    }
    else if (levelNumber == 3 && (playerScore.getScore() >= POINTS_LEVEL3))
    {
      hiscore app = playerScore;
      reset();
      state = gamestate.WAITING;
      playerScore = app;
      
      levelNumber = 3;
    }
    else if (levelNumber == 4 && (playerScore.getScore() >= POINTS_LEVEL4))
    {
      player1.die();
      state = gamestate.GAMEOVER;
      
      levelNumber = 4;
    }
  }
  
  
  //the main method that "makes things happen"
  void executeCommands()
  {
    //should avoid movement if game has not yet started
    millis = millis();
    
    if (state == gamestate.GAME)
    {
      //init variables and stuff when beginning a new level
      //should probably use if statements a few other control variables
      player1.updateMaluses();
      
      //update enemies
      movenemies();
      
      //update player and level variables
      move();
      
      //work on shots
      ArrayList<shot> pshots = player1.getShots();
      ArrayList<enemy> enemylist = spawner.getEnemyList();
      
      //update
      //player
      for (int i = pshots.size() - 1; i >= 0; i--)
      {
        pshots.get(i).update();
        if (pshots.get(i).isOutOfTheLevel())
          pshots.remove(i);
      }
      
      //enemies
      for (enemy e : enemylist)
      {
        ArrayList<shot> eshots = e.getShots();
        for (int i = eshots.size() - 1; i >= 0; i--)
        {
          eshots.get(i).update();
          if (eshots.get(i).isOutOfTheLevel())
            eshots.remove(i);
        }
      }
      
      //CHECK COLLISIONS
      //player
      for (int i = pshots.size() - 1; i >= 0; i--)
      {
        for (int j = enemylist.size() - 1; j >= 0; j--)
        {     
          float tX = pshots.get(i).getPosX(); //if I remove a shot, this is still exptected to be there at this point
          float tY = pshots.get(i).getPosY();
          if (enemylist.get(j).checkCollision(tX, tY))
          {
            enemylist.get(j).applyEffects(pshots.get(i));
            pshots.remove(i);
            break;
          }
        }
      }
      //then check for enemy killing
      for (int j = enemylist.size() - 1; j >= 0; j--)
      {
        if (spawner.checkKilling(j))
        {
          playerScore.add(enemylist.get(j).getPointsValue());
        }
      }
      
      //enemies
      for (enemy e : enemylist)
      {
        ArrayList<shot> eshots = e.getShots();
        for (int i = eshots.size() - 1; i >= 0; i--)
        {
          if (player1.checkCollision(eshots.get(i).getPosX(), eshots.get(i).getPosY()))
          {
            player1.applyEffects(eshots.get(i));
            eshots.remove(i);
            
          }
        }
      }
      
      //spawn new shots
      //player
      if (player1.canShoot())
      {
        player1.addShot(enemylist);
        //player1.addShot(spawner.getEnemyList());
      }
      
      //enemies
      ArrayList<player> plist = new ArrayList<player>();
      plist.add(player1);
      for (enemy e : enemylist)
      {
        if (e.canShoot())
        {
          //println("instantiate shot");
          e.addShot(plist);
        }
      }
      
      //check if player has been defeated
      if (player1.getLife() <= 0)
      {
        //println("player dead");
        player1.die();
        state = gamestate.GAMEOVER;
      }
      
      //check player collisions
      if (checkCollisionsWithLevel(player1) || checkCollisionsWithEnemies(player1))
      {
        //println("player dead");
        player1.die();
        state = gamestate.GAMEOVER;
      }
     
      //spawn enemies
      if (spawner.canSpawn())
      {
        spawner.spawnEnemy(currentlevel_o, player1.getPosX(), player1.getPosY());
      } 
      
      //set offsets for display
      setLevelOffset();
      setPlayerOffset();
      setShotsOffset();
      setEnemiesOffset();
      
      checkNextLevel();
    }
    else if (state == gamestate.START)
    {
      //press start
      if (enterKey)
      {
        enterKey = false;
        state = gamestate.WAITING;
      }
    }
    else if (state == gamestate.WAITING)
    { 
      //press "enter" to continue
      if (enterKey)
      {
        enterKey = false;
        levelNumber += 1;
        startGame();
        state = gamestate.GAME;
      }
    }
    else if (state == gamestate.GAMEOVER)
    {
      if (player1.isDying())
      {
        //update player
        move();
        
        //sets offsets for display
        setPlayerOffset();
      }
      else
      {
        int i = leaderBoard.addScore(playerScore);
        if (i < leaderBoard.getShowscore())
        {
          state = gamestate.INSERT_NAME;
        }
        else
        {
          state = gamestate.ENDGAME;
        }
      }
    }
    else if (state == gamestate.INSERT_NAME)
    {
      if (enterKey)
      {
        enterKey = false;
        leaderBoard.updateLastName(playerScore.getName());
        leaderBoard.saveleaderboard();
        state = gamestate.ENDGAME;
      }
    }
    else if (state == gamestate.ENDGAME)
    {
      if (enterKey)
        {
          enterKey = false;
          state = gamestate.START;
          reset();
        }
    }
  }
  
  
  //the main method that "makes things happen"
  
  
  void displayTitle()
  {
    textAlign(CENTER);
    float tX = WIDTH / 2;
    float tY = HEIGHT / 5;
    textSize(HEIGHT / 10);
    fill(TEXT_COLOR);
    text(TITLE, tX, tY);
  }
  
  void displayControls()
  {
    textAlign(CENTER);
    float tX = WIDTH / 2;
    float tY = HEIGHT - HEIGHT / 5;
    textSize(HEIGHT / 20);
    fill(TEXT_COLOR);
    text("Controls:\nw/a/s/d move character", tX, tY);
  }
  
  void displayStart()
  {
    int delta = millis - lastTickBlinking;
    if (delta * 0.001 >= BLINKING_TIME)
    {
      lastTickBlinking += delta;
    }
    else if (delta * 0.001 >= (BLINKING_TIME / 2))
    {
      //display nothing
    }
    else
    {
      textAlign(CENTER);
      float tX = WIDTH / 2;
      float tY = HEIGHT / 2;
      textSize(HEIGHT / 15);
      fill(TEXT_COLOR);
      text("Press ENTER to play", tX, tY);
    }
  }
  
  void displayContinue()
  {
    textAlign(CENTER);
    float tX = WIDTH / 2;
    float tY = HEIGHT - HEIGHT / 10;
    textSize(HEIGHT / 15);
    fill(TEXT_COLOR);
    text("Press ENTER to continue", tX, tY);
  }
  
  void displayHiScore()
  {
    textAlign(CENTER);
    float tX = WIDTH / 2;
    float tY = HEIGHT / 6;
    textSize(HEIGHT / 10);
    fill(TEXT_COLOR);
    text("Score " + playerScore.getScore(), tX, tY);
  }
  
  void displayInsertName()
  {
    int delta = millis - lastTickBlinking;
    textAlign(CENTER);
    float tX = WIDTH / 2;
    float tY = HEIGHT / 2 - HEIGHT / 15;
    textSize(HEIGHT / 15);
    fill(TEXT_COLOR);
    text("INSERT NAME", tX, tY);
    
    tY += HEIGHT / 15;
    if (delta * 0.001 >= BLINKING_TIME)
    {
      lastTickBlinking += delta;
    }
    else if (delta * 0.001 >= (BLINKING_TIME / 2))
    {
      //display nothing
    }
    else
    {
      text(playerScore.getName(), tX, tY);
    }
  }
  
  void displayLeaderboard()
  {
    ArrayList<hiscore> hiscores = leaderBoard.getScores();
    textAlign(CENTER);
    float tX = WIDTH / 4;
    float tY = HEIGHT / 5 + HEIGHT / 17;
    textSize(HEIGHT / 22);
    fill(TEXT_COLOR);
    text("LEADERBOARD", tX * 2, tY);
    tY += HEIGHT / 20;
    text(NAME_HEADER, tX, tY);
    text(SCORE_HEADER, tX * 3, tY);
    tY += HEIGHT / 20;
    for (int i = 0; i < min(leaderBoard.getShowscore(), hiscores.size()); i++)
    {
      text(hiscores.get(i).getName(), tX, tY);
      text(hiscores.get(i).getScore(), tX * 3, tY);
      tY += HEIGHT / 20;
    }
  }
  
  void displayStatusBar()
  {
    stroke(0);
    fill(255, 150);
    rect(0, 0, WIDTH, HEIGHT / 20);
  }
  
  void displayScoreIngame()
  {
    textAlign(RIGHT);
    float tX = WIDTH / 5;
    float tY = HEIGHT / 22;
    fill(255, 255);
    fill(0);
    textSize(HEIGHT / 20);
    text("Score " + playerScore.getScore(), tX, tY);
  }
  
  void displayPlayerLife()
  {
    textAlign(LEFT);
    float tX = WIDTH - (WIDTH / 5);
    float tY = HEIGHT / 22;
    fill(255, 255);
    fill(0);
    textSize(HEIGHT / 20);
    text("Life: " + player1.getLife(), tX, tY);
  }
  
  
  
  void display()
  {
    if (state == gamestate.GAME) //ACTUAL GAME
    {
      currentlevel_bg.display();
      currentlevel_o.display();
      player1.display();
      
      for (enemy e : spawner.getEnemyList())
      {
        e.display();
        for (shot s : e.getShots())
          s.display();
      }
      
      for (shot s : player1.getShots())
      {
        s.display();
      }
      
      displayStatusBar();
      displayPlayerLife();
      displayScoreIngame();
    }
    else if (state == gamestate.START) //MAIN MENU
    {
      displayTitle();
      displayControls();
      displayStart();
    }
    else if (state == gamestate.WAITING) //BEFORE A LEVEL
    {
      if (playerScore != null)
        displayHiScore();
      displayLeaderboard();
      displayContinue();
    }
    else if (state == gamestate.GAMEOVER) //AFTER DYING
    {
      if (player1.isDying())
      {
        currentlevel_bg.display();
        currentlevel_o.display();
        player1.display();
        
        for (enemy e : spawner.getEnemyList())
        {
          e.display();
          for (shot s : e.getShots())
            s.display();
        }
        
        for (shot s : player1.getShots())
        {
          s.display();
        }
      }
    }
    else if (state == gamestate.INSERT_NAME) //INSERTING NAME
    {
      displayHiScore();
      displayInsertName();
      displayContinue();
      
    }
    else if (state == gamestate.ENDGAME) //LAST SCREEN
    {
      displayHiScore();
      displayLeaderboard();
      displayContinue();
    }
    
  }
  
  level getCurrentlevel_bg()
  {
    return currentlevel_bg;
  }
  
  level getCurrentlevel_o()
  {
    return currentlevel_o;
  }
  
  void setLevelOffset()
  {
    currentlevel_bg.setOffset(-1 * offsetX, -1 * offsetY);
    currentlevel_o.setOffset(-1 * offsetX, -1 * offsetY);
  }

  void setState(gamestate state)
  {
    this.state = state;
  }
}

class hiscore {
    private String name;
    private int score;
    private int min;
    private int max;

    // Create a score with default values
    hiscore() 
    {
      this.name = "New Player";
      this.score = 0;
      this.min = 0;
      this.max = Integer.MAX_VALUE;
    }

    // Create a score with the selected initial name and score
    hiscore (int initial_score)
    {
        if (initial_score < min || initial_score > max)
        {
            throw new IllegalArgumentException("Initial score " + initial_score + " should be in range [" + min + ", " + max + "]");
        }
        score = initial_score;
    }

    // Create a score with the selected name, initial score, minimum and maximum score
    // if min score >= max score, use default values
    hiscore (int initial_score, int min, int max)
    {
        if (min < max)
        {
            this.min = min;
            this.max = max;
        }
        if (initial_score < min || initial_score > max)
        {
            throw new IllegalArgumentException("Initial score " + initial_score + " should be in range [" + min + ", " + max + "]");
        }
        score = initial_score;
    }

    // getter methods
    int getScore() 
    { 
      return score;
    }
    
    int getMin() 
    { 
      return min;
    }
    
    int getMax() 
    {
      return max;
    }
    
    String getName()
    {
      return name;
    }
    
    // setter methods
    public void setName(String name)
    {
      this.name = name;
    }

    // add point to this score
    // if the new score exceed this.max, this.max is used as new
    // score
    public void add(int point)
    {
        if (point >= 0 && this.max - score <= point)
          score = this.max;
        else if (point < 0 && this.min + point >= score)
          score = this.min;
        else score += point;
    }

    // subtract point to this score
    public void sub(int point)
    {
        if (point < 0 && this.max - score <= point)
          score = this.max;
        else if ( point >= 0 && this.min + point >= score)
          score = this.min;
        else score -= point;
    }

    public String toString()
    {
        return name + ": " + Integer.valueOf(score).toString();
    }


}

//import java.text.SimpleDateFormat;
//import java.util.Date;

// import Score;

public class leaderboard {
    private ArrayList<hiscore> hiscores;
    private String filename;
    private int minscore = 0;
    private int maxscore = Integer.MAX_VALUE;
    private int showscore = 10; // number of scores to show
    private int lastInserted;

    // Create a new leaderboard with default filename
    leaderboard()
    {
        filename = new java.text.SimpleDateFormat("yyyy_MM_dd_kk_mm_ss_SS").format(new java.util.Date());
        filename += ".scores";
        hiscores = new ArrayList<hiscore>();
    }
    
    // initialize a new score board file
    void initLeaderboardFile(String filename)
    {
      Table t = new Table();
      t.addColumn(NAME_HEADER);
      t.addColumn(SCORE_HEADER);
      saveTable(t, "data/" + filename);
    }
        
    void saveleaderboard()
    {
      Table t = new Table();
      t.addColumn(NAME_HEADER);
      t.addColumn(SCORE_HEADER);
      for (int i = 0; i < min(showscore, hiscores.size()); i++)
      {
        TableRow r = t.addRow();
        r.setString(NAME_HEADER, hiscores.get(i).getName());
        r.setInt(SCORE_HEADER, hiscores.get(i).getScore());
      }
      saveTable(t, "data/" + this.filename, "csv");
    }

    // Create a leaderboard reading the scores from the given filename
    leaderboard(String filename)
    {
      this.filename = filename;
      Table table = loadTable(filename, "header");
      hiscores = new ArrayList<hiscore>();
      for (TableRow row : table.rows())
      {
        hiscore s = new hiscore(row.getInt(SCORE_HEADER), this.minscore, this.maxscore);
        s.setName(row.getString(NAME_HEADER));
        hiscores.add(s);
      }
      this.sortScores();
    }
    
    void updateLastName(String newname)
    {
      hiscore s = this.getLastInserted();
      s.setName(newname);
    }
    
    void updateName(String newname, int scoreidx)
    {
      hiscore s = hiscores.get(scoreidx);
      s.setName(newname);
    }
    
    void sortScores()
    {
      hiscores.sort((a, b) -> b.getScore() - a.getScore());
    }
    
    void setMinScore(int minscore)
    {
      this.minscore = minscore;
    }
    
    void setMaxScore(int maxscore)
    {
      this.maxscore = maxscore;
    }
    
    void setShowScore(int showscore)
    {
      this.showscore = showscore;
    }

    String getFilename()
    { 
      return filename;
    }
    
    ArrayList<hiscore> getScores()
    {
      return this.hiscores;
    }
    
    int addScore(hiscore s)
    {
      hiscores.add(s);
      this.sortScores();
      lastInserted = hiscores.indexOf(s);
      return lastInserted;
    }
    
    int getShowscore()
    {
      return showscore;
    }
    
    hiscore getLastInserted()
    {
      return hiscores.get(lastInserted);
    }
    
}

class level
{
  private tile[] tiles;
  private layer tilesLayer;
  Table csvLevel;
  
  level(layer l)
  {
    this.tilesLayer = l;
  }
  
  void init(String lev, PImage tilesheet)
  {
    int type, posX, posY;
    int tileNumber = 0;
    csvLevel = loadTable(lev, "csv");
    tiles = new tile[csvLevel.getColumnCount() * csvLevel.getRowCount()];
    for (int k = 0; k < tiles.length; k++)
      tiles[k] = new tile();
    for (int i = 0; i < csvLevel.getColumnCount(); i++)
    {
      for (int j = 0; j < csvLevel.getRowCount(); j++)
      {
        type = csvLevel.getInt(j, i);
        posX = TILESIZE * i;
        posY = TILESIZE * j;
        tiles[tileNumber].init(tilesheet, tileNumber, posX, posY, type);
        tileNumber++;
        
      }
    }
  }
  
  boolean isColliding(int tileToCheck, float x, float y, boolean isLevelCollision)
  {
    if (!isLevelCollision)
      return tiles[tileToCheck].checkCollision(x, y);
    else
    {
      if (tiles[tileToCheck].getType() != -1)
        return tiles[tileToCheck].checkCollision(x, y);
    }
    return false;
  }
  

  void setOffset(float offsetX, float offsetY)
  {
    for (tile t : tiles)
    {
      t.setOffsetX(offsetX);
      t.setOffsetY(offsetY);
    }
  }
  
  void setOffsetX(float offsetX)
  {
    for (tile t: tiles)
      t.setOffsetX(offsetX);
  }
  
  void setOffsetY(float offsetY)
  {
    for (tile t: tiles)
      t.setOffsetY(offsetY);
  }
  
  void display()
  {
    for (tile t : tiles)
      t.display();
  }
  
  
  void highlight(int tileNumber)
  {
    tiles[tileNumber].highlight();
  }
  
  
  tile[] getTiles()
  {
    return tiles;
  }
  
  layer getTilesLayer()
  {
    return tilesLayer;
  }
  
  Table getCsvLevel()
  {
    return csvLevel;
  }
  
}

class particle
{
  PVector position;
  PVector displayPosition;
  PVector velocity;
  PVector acceleration;
  float lifespan;

  particle(PVector l)
  {
    velocity = new PVector(random(-100, 100), random(-100, 100));
    position = l.copy();
    displayPosition = l.copy();
    lifespan = 1.0;
  }


  // Method to update position
  void update(float deltaSeconds)
  {
    position.add(velocity.copy().mult(deltaSeconds));
    lifespan -= deltaSeconds;
  }

  // Method to display
  void display()
  {
    stroke(255, lifespan * 255);
    fill(255, lifespan * 255);
    ellipse(displayPosition.x, displayPosition.y, 8, 8);
  }

  // Is the particle still useful?
  boolean isDead()
  {
    if (lifespan < 0.0)
    {
      return true;
    }
    else 
    {
      return false;
    }
  }
  
  void setOffset(PVector offset)
  {
    displayPosition = position.copy();
    displayPosition.add(offset);
  }
}

// A class to describe a group of Particles
// An ArrayList is used to manage the list of Particles 

class particlesystem
{
  ArrayList<particle> particles;
  PVector origin;
  int lastTick;

  particlesystem(PVector position)
  {
    origin = position.copy();
    particles = new ArrayList<particle>();
    lastTick = millis();
  }

  void addParticle()
  {
    particles.add(new particle(origin));
  }

  void update()
  {
    int delta = millis - lastTick;
    for (int i = particles.size() - 1; i >= 0; i--)
    {
      particle p = particles.get(i);
      p.update(delta * 0.001);
      if (p.isDead())
      {
        particles.remove(i);
      }
    }
    lastTick += delta;
  }
  
  boolean isExploding()
  {
    return (particles.size() != 0);
  }
  
  void setOffset(PVector offset)
  {
    for (particle p : particles)
    {
      p.setOffset(offset);
    }
  }
  
  void display()
  {
    for( particle p : particles)
      p.display();
  }
}

class player extends character
{
  
  private heroes herotype; //getter
  
  player(PImage spritesheet, float posX, float posY, heroes herotype)
  {
    super(spritesheet, posX, posY);
    this.herotype = herotype;
    life = LIFE_PLAYER;
    shotDistance = SHOT_PLAYER_DISTANCE;
    shotTime = SHOT_PLAYER_COOLDOWN;
    speed = SPEED_PLAYER;
    initialSpeed = speed;
  }
  
  shot addShot(ArrayList<? extends character> targets)
  {
    shot s = super.addShot(targets);
    if (s != null)
    {
      s.setSpeed(SHOT_PLAYER_SPEED);
      s.setDamage(SHOT_PLAYER_DAMAGE);
      s.setColor(SHOT_PLAYER_COLOR);
      s.setSpeedMalus(SHOT_PLAYER_SPEEDMALUS);
    }
    return s;
  }
  
  heroes getHerotype()
  {
    return herotype;
  }

}

class shot
{
  float posX;
  float posY;
  float displayPosX;
  float displayPosY;
  float damage;
  float speedMalus;
  float speed;
  PVector shotDirection;
  color col;
  int lastTick;
  
  shot(float posX, float posY)
  {
    this.posX = posX;
    this.posY = posY;
    this.displayPosX = posX;
    this.displayPosY = posY;
    lastTick = millis();
  }
  
  boolean isOutOfTheLevel()
  {
    if ((posX < 0) || (posX > TOTALHORIZONTALTILES * TILESIZE) ||
        (posY < 0) || (posY > TOTALVERTICALTILES * TILESIZE) )
        return true;
    return false;
  }
  
  void update()
  {
    int delta = millis - lastTick;
    posX += delta * 0.001 * speed * shotDirection.x;
    posY += delta * 0.001 * speed * shotDirection.y;
    lastTick += delta;
  }
  
  void display()
  {
    stroke(0);
    fill(col);
    ellipse(displayPosX, displayPosY, SHOT_DIMENSION, SHOT_DIMENSION);
  }
  
  float getPosX()
  {
    return posX;
  }
  
  float getPosY()
  {
    return posY;
  }
  
  float getSpeed()
  {
    return speed;
  }
  
  float getDamage()
  {
    return damage;
  }
  
  float getSpeedMalus()
  {
    return speedMalus;
  }
  
  void setOffset(float offsetX, float offsetY)
  {
    displayPosX = posX + offsetX;
    displayPosY = posY + offsetY;
  }
  
  void setOffsetX(float offsetX)
  {
    displayPosX = posX + offsetX;
  }
  
  void setOffsetY(float offsetY)
  {
    displayPosY = posY + offsetY;
  }
  
  void setSpeed(float speed)
  {
    this.speed = speed;
  }
  
  void setDamage(float damage)
  {
    this.damage = damage;
  }
  
  void setSpeedMalus(float speedMalus)
  {
    this.speedMalus = speedMalus;
  }
  
  void setColor(color col)
  {
    this.col = col;
  }
  
  void setShotDirection(PVector d)
  {
    this.shotDirection = d;
  }
}

class tile
{
  protected float posX;
  protected float posY;
  protected float displayPosX;
  protected float displayPosY;
  protected int tileNumber; 
  protected int type = -1;
  protected PImage refTile;
  boolean highlighted;
  
  tile()
  {}
  
  void init (PImage tilesheet, int tileNumber, float posX, float posY, int type)
  {
    this.tileNumber = tileNumber;
    this.posX = posX;
    this.posY = posY;
    this.displayPosX = posX;
    this.displayPosY = posY;
    this.type = type;

    int sheetX = type % (tilesheet.width / TILESIZE);
    int sheetY = type / (tilesheet.width / TILESIZE);
    refTile = tilesheet.get(sheetX * TILESIZE, sheetY * TILESIZE, TILESIZE, TILESIZE);
  }
  
  void setOffsetX(float offsetX)
  {
    displayPosX = posX + offsetX;
  }
  
  void setOffsetY(float offsetY)
  {
    displayPosY = posY + offsetY;
  }
  
  void display()
  {
    image(refTile, displayPosX, displayPosY);

    
    //debug
    if (highlighted)
    {
      noFill();
      stroke(HL_COLOR);
      strokeWeight(1);
      rect(displayPosX, displayPosY, TILESIZE, TILESIZE);
    }
    highlighted = false;
    
  }
  
  //debug
  void highlight()
  {
    highlighted = true;
  }  
  
  boolean checkCollision(float x, float y)
  {
    return ( (x >= posX) && (x <= posX + TILESIZE) && (y >= posY) && (y <= posY + TILESIZE) );

  }
  
  float getPosX()
  {
    return posX;
  }
  
  float getPosY()
  {
    return posY;
  }
  
  float getDisplayPosX()
  {
    return displayPosX;
  }
  
  float getDisplayPosY()
  {
    return displayPosY;
  }
  
  
  
  int getTileNumber()
  {
    return tileNumber;
  }
  
  int getType()
  {
    return type;
  }
  
  PImage getRefTile()
  {
    return refTile;
  }
  
  
  //makes sense?
  void setTileNumber(int tileNumber)
  {
    this.tileNumber = tileNumber;
  }
  
  void setType(int type)
  {
    this.type = type;
  }
  
  void setRefTile(PImage refTile)
  {
    this.refTile = refTile;
  }
}
