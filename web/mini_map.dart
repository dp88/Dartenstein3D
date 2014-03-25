library mini_map;

import 'dart:html';
import 'dart:math' as Math;
import 'player.dart';

class MiniMap {
   CanvasElement c;
   CanvasElement o;
   
   var cctx;
   var octx;
   
   var map;
   num mapWidth = 0;  // number of map blocks in x-direction
   num mapHeight = 0;  // number of map blocks in y-direction
   num miniMapScale = 8;  // how many pixels to draw a map block
   
   MiniMap(CanvasElement c, CanvasElement o, var map){
      this.c = c;
      this.o = o;
      
      this.cctx = this.c.getContext("2d");
      this.octx = this.o.getContext("2d");
      
      this.map = map;
      this.mapWidth = map[0].length;
      this.mapHeight = map.length;
   }
   
   void drawMiniMap() {
      // draw the topdown view minimap
      c
         ..width = mapWidth * miniMapScale  // resize the internal canvas dimensions 
         ..height = mapHeight * miniMapScale
         ..style.width = (mapWidth * miniMapScale).toString() + "px"  // resize the canvas CSS dimensions
         ..style.height = (mapHeight * miniMapScale).toString() + "px";
      
      o
         ..width = mapWidth * miniMapScale 
         ..height = mapHeight * miniMapScale
         ..style.width = (mapWidth * miniMapScale).toString() + "px"
         ..style.height = (mapHeight * miniMapScale).toString() + "px";

      // loop through all blocks on the map
      for (var y=0; y < mapHeight; y++) {
         for (var x=0; x < mapWidth; x++) {
            var wall = map[y][x];
            if (wall > 0) {  // if there is a wall block at this (x,y) ...
               cctx
                  ..fillStyle = "rgb(200,200,200)"
                  ..fillRect(  // ... then draw a block on the minimap
                     x * miniMapScale,
                     y * miniMapScale,
                     miniMapScale,miniMapScale
               );
            }
         }
      }
   }
   
   void updateObjects(Player p){
      octx
         ..clearRect(0, 0, c.width, c.height)
         ..fillRect(     // draw a dot at the current player position
            p.x * miniMapScale - 2, 
            p.y * miniMapScale - 2,
            4, 4)
         ..beginPath()
         ..moveTo(p.x * miniMapScale, p.y * miniMapScale)
         ..lineTo(
            (p.x + Math.cos(p.rot) * 4) * miniMapScale,
            (p.y + Math.sin(p.rot) * 4) * miniMapScale)
         ..closePath()
         ..stroke();
   }
}
