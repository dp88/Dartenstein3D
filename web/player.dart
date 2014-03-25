library player;

import 'dart:html';
import 'dart:math' as Math;

class Player {
   num x = 16;  // current x, y position of the player
   num y = 10;
   num dir = 0;  // the direction that the player is turning, either -1 for left or 1 for right.
   num rot = 0;  // the current angle of rotation
   num speed = 0;  // is the playing moving forward (speed = 1) or backwards (speed = -1).
   num moveSpeed = 0.18;  // how far (in map units) does the player move each step/update
   num rotSpeed = 6 * Math.PI / 180;  // how much does the player rotate each step/update (in radians)
   
   var map;
   num mapWidth;
   num mapHeight;
   
   Player(var map){
      this.map = map;
      this.mapWidth = map[0].length;
      this.mapHeight = map.length;
      
      document..onKeyDown.listen(handleKeyDown)
              ..onKeyUp.listen(handleKeyUp);
   }
   
   void move() {
      num moveStep = speed * moveSpeed;  // player will move this far along the current direction vector

      rot += dir * rotSpeed; // add rotation if player is rotating (player.dir != 0)

      num newX = x + Math.cos(rot) * moveStep; // calculate new player position with simple trigonometry
      num newY = y + Math.sin(rot) * moveStep;

      if (isBlocking(newX, newY)) { // are we allowed to move to the new position?
         return; // no, bail out.
      }
      
      x = newX; // set new position
      y = newY;
   }
   
   bool isBlocking(x,y) {
      // first make sure that we cannot move outside the boundaries of the level
      if (y < 0 || y >= mapHeight || x < 0 || x >= mapWidth)
         return true;

      // return true if the map block is not 0, ie. if there is a blocking wall.
      return (map[y.floor()][x.floor()] != 0); 
   }

   
   void handleKeyDown(e){
      switch (e.keyCode) { // which key was pressed?
         case 38: // up, move player forward, ie. increase speed
            speed = 1;
            break;
         case 40: // down, move player backward, set negative speed
            speed = -1;
            break;
         case 37: // left, rotate player left
            dir = -1;
            break;
         case 39: // right, rotate player right
            dir = 1;
            break;
      }
   }
   
   void handleKeyUp(e){
      switch (e.keyCode) {
         case 38:
         case 40:
            speed = 0;
            break; 
         case 37:
         case 39:
            dir = 0;
            break;
       }
   }
}