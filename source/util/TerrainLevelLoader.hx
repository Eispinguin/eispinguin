package util;

import collision.GroundPiece;
import collision.TerrainManager;
import editor.LevelDocument;
import openfl.Assets;
import util.GroundPieceDefinition;

typedef TerrainLevel =
{
    var terrain:TerrainManager;

    var playerX:Float;
    var playerY:Float;

    var music:String;
}

class TerrainLevelLoader
{
    public static function load(path:String, library:GroundPieceLibrary):TerrainLevel
    {
        var document = LevelDocument.fromJson(Assets.getText(path));
        var terrain = new TerrainManager(document.width, document.height);
        var pieces:Array<GroundPiece> = [];

        for (placement in document.pieces)
        {
            var definition = library.getById(placement.id);

            pieces.push(new GroundPiece(definition.bitmap, placement.x, placement.y, definition.type, definition.collisionMask));
        }

        terrain.addPieces(pieces);

        return {terrain: terrain, playerX: document.playerX, playerY: document.playerY, music: document.music};
    }
}