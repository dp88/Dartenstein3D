library raycaster;

import 'dart:html';
import 'dart:math' as Math;
import 'player.dart';

class Raycaster {
   static num screenWidth = 320;
   static num screenHeight = 200;
   static num stripWidth = 2;
   static num twoPI = Math.PI * 2;
   static num numTextures = 4;
   
   num fov;
   num numRays;
   num fovHalf;
   num viewDist;
   
   var screenStrips = <DivElement>[];
   
   Player player;
   var map;
   
   num mapWidth = 0;  // number of map blocks in x-direction
   num mapHeight = 0;  // number of map blocks in y-direction

   Raycaster(Player p, var m){
      this.player = p;
      this.map = m;
      
      fov = 60 * Math.PI / 180;
      numRays = (screenWidth / stripWidth).ceil();
      fovHalf = fov / 2;
      viewDist = (screenWidth / 2) / Math.tan((fov / 2));
      
      this.mapWidth = map[0].length;
      this.mapHeight = map.length;
   }
   
   void initScreen() {

      Element screen = querySelector("#screen");

      for (var i=0;i<screenWidth;i+=stripWidth) {
         DivElement strip = new DivElement();
         ImageElement img = new ImageElement();
         
         strip.style
            ..position = "absolute"
            ..left = i.toString() + "px"
            ..width = stripWidth.toString() + "px"
            ..height = "0px"
            ..overflow = "hidden"
            ..backgroundColor = "magenta";

         img
            ..src = "walls.png"
            ..style.position = "absolute"
            ..style.left = "0px";

         strip.nodes.add(img);         
         
         screenStrips.add(strip);
         screen.nodes.add(strip);
      }

   }

   
   void castRays() {

      num stripIdx = 0;

      for (num i=0; i < numRays; i++) {
         // where on the screen does ray go through?
         var rayScreenPos = (-numRays/2 + i) * stripWidth;

         // the distance from the viewer to the point on the screen, simply Pythagoras.
         var rayViewDist = Math.sqrt(rayScreenPos*rayScreenPos + viewDist*viewDist);

         // the angle of the ray, relative to the viewing direction.
         // right triangle: a = sin(A) * c
         var rayAngle = Math.asin(rayScreenPos / rayViewDist);

         castSingleRay(
               player.rot + rayAngle,  // add the players viewing direction to get the angle in world space
               stripIdx++
         );
      }
   }

   void castSingleRay(rayAngle, stripIdx) {

      // first make sure the angle is between 0 and 360 degrees
      rayAngle %= twoPI;
      if (rayAngle < 0) rayAngle += twoPI;

      // moving right/left? up/down? Determined by which quadrant the angle is in.
      var right = (rayAngle > twoPI * 0.75 || rayAngle < twoPI * 0.25);
      var up = (rayAngle < 0 || rayAngle > Math.PI);

      var wallType = 0;

      // only do these once
      var angleSin = Math.sin(rayAngle);
      var angleCos = Math.cos(rayAngle);

      var dist = 0;  // the distance to the block we hit
      var xHit = 0;  // the x and y coord of where the ray hit the block
      var yHit = 0;

      var textureX;  // the x-coord on the texture of the block, ie. what part of the texture are we going to render
      var wallX;  // the (x,y) map coords of the block
      var wallY;

      var wallIsHorizontal = false;

      num slope;
      num x;
      num y;
      
      // first check against the vertical map/wall lines
      // we do this by moving to the right or left edge of the block we're standing in
      // and then moving in 1 map unit steps horizontally. The amount we have to move vertically
      // is determined by the slope of the ray, which is simply defined as sin(angle) / cos(angle).

      slope = angleSin / angleCos;    // the slope of the straight line made by the ray
      var dXVer = right ? 1 : -1;   // we move either 1 map unit to the left or right
      var dYVer = dXVer * slope;    // how much to move up or down

      x = right ? (player.x).ceil() : (player.x).floor(); // starting horizontal position, at one of the edges of the current map block
      y = player.y + (x - player.x) * slope;         // starting vertical position. We add the small horizontal step we just made, multiplied by the slope.

      while (x >= 0 && x < mapWidth && y >= 0 && y < mapHeight) {
         var wallX = (x + (right ? 0 : -1)).floor();
         var wallY = y.floor();

         // is this point inside a wall block?
         if (map[wallY][wallX] > 0) {
            var distX = x - player.x;
            var distY = y - player.y;
            dist = distX*distX + distY*distY;   // the distance from the player to this point, squared.

            wallType = map[wallY][wallX]; // we'll remember the type of wall we hit for later
            textureX = y % 1; // where exactly are we on the wall? textureX is the x coordinate on the texture that we'll use later when texturing the wall.
            if (!right) textureX = 1 - textureX; // if we're looking to the left side of the map, the texture should be reversed

            xHit = x;   // save the coordinates of the hit. We only really use these to draw the rays on minimap.
            yHit = y;

            wallIsHorizontal = true;

            break;
         }
         x += dXVer;
         y += dYVer;
      }



      // now check against horizontal lines. It's basically the same, just "turned around".
      // the only difference here is that once we hit a map block, 
      // we check if there we also found one in the earlier, vertical run. We'll know that if dist != 0.
      // If so, we only register this hit if this distance is smaller.

      slope = angleCos / angleSin;
      var dYHor = up ? -1 : 1;
      var dXHor = dYHor * slope;
      y = up ? (player.y).floor() : (player.y).ceil();
      x = player.x + (y - player.y) * slope;

      while (x >= 0 && x < mapWidth && y >= 0 && y < mapHeight) {
         var wallY = (y + (up ? -1 : 0)).floor();
         var wallX = (x).floor();
         if (map[wallY][wallX] > 0) {
            var distX = x - player.x;
            var distY = y - player.y;
            var blockDist = distX*distX + distY*distY;
            if (dist == 0 || blockDist < dist) {
               dist = blockDist;
               xHit = x;
               yHit = y;

               wallType = map[wallY][wallX];
               textureX = x % 1;
               if (up) textureX = 1 - textureX;
            }
            break;
         }
         x += dXHor;
         y += dYHor;
      }

      if (dist != 0) {
         drawRay(xHit, yHit);

         DivElement strip = screenStrips[stripIdx];
         ImageElement texture = (strip.nodes.length > 0) ? strip.nodes[0] : new ImageElement();

         dist = Math.sqrt(dist);

         // use perpendicular distance to adjust for fish eye
         // distorted_dist = correct_dist / cos(relative_angle_of_ray)
         dist = dist * Math.cos(player.rot - rayAngle);

         // now calc the position, height and width of the wall strip

         // "real" wall height in the game world is 1 unit, the distance from the player to the screen is viewDist,
         // thus the height on the screen is equal to wall_height_real * viewDist / dist

         var height = (viewDist / dist).round();

         // width is the same, but we have to stretch the texture to a factor of stripWidth to make it fill the strip correctly
         var width = height * stripWidth;

         // top placement is easy since everything is centered on the x-axis, so we simply move
         // it half way down the screen and then half the wall height back up.
         var top = ((screenHeight - height) / 2).round();

         strip.style
            ..height = height.toString() + "px"
            ..top = top.toString() + "px";

         var texX = (textureX * width).round();

         if (texX > width - stripWidth)
             texX = width - stripWidth;

         texture.style
            ..height = (height * numTextures).floor().toString() + "px"
            ..width = (width*2).floor().toString() +"px"
            ..top = "-" + (height * (wallType-1)).floor().toString() + "px"
            ..left = (-texX).toString() + "px";  

      }

   }
   
   void drawRay(rayX, rayY) {
      var miniMapObjects = querySelector("#minimapobjects");
      var objectCtx = miniMapObjects.getContext("2d");
      num miniMapScale = 8;

      objectCtx
         ..strokeStyle = "rgba(0,100,0,0.3)"
         ..lineWidth = 0.5
         ..beginPath()
         ..moveTo(player.x * miniMapScale, player.y * miniMapScale)
         ..lineTo(
            rayX * miniMapScale,
            rayY * miniMapScale
         )
         ..closePath()
         ..stroke();
   }

}