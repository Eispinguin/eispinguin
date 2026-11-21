package collision;

import openfl.display.BitmapData;

enum abstract GroundPieceType(Int) from Int to Int
{
    var ground = 1;
    var solid = 2;
    var transparent = 3;
}

class GroundPiece
{
    public var bitmap(default, null):BitmapData;

    public var collisionMask(default, null):BitmapData;

    public var x:Int;
    public var y:Int;

    public var type:GroundPieceType;

    public function new(bitmap:BitmapData, x:Int, y:Int, type:GroundPieceType, ?collisionMask:BitmapData)
    {
        if (bitmap == null)
        {
            throw "Groundpiece requires an image!";
        }

        if (collisionMask != null)
        {
            if (collisionMask.width != bitmap.width || collisionMask.height != bitmap.height)
            {
                trace("Collision mask must have the same dimensions as it's image!");
            }
        }

        this.bitmap = bitmap;
        this.collisionMask = collisionMask;

        this.x = x;
        this.y = y;

        this.type = type;
    }
}