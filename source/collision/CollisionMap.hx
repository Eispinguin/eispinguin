package collision;

import haxe.io.Bytes;

class CollisionMap
{
    public static inline var empty:Int = 0;
    public static inline var ground:Int = 1;
    public static inline var solid:Int = 2;

    public var width(default, null):Int;
    public var height(default, null):Int;

    public var outsideIsSolid:Bool = true;

    var data:Bytes;

    public function new(width:Int, height:Int)
    {
        if (width <= 0 || height <= 0)
        {
            throw "CollisionMap dimensions must be positive!";
        }

        this.width = width;
        this.height = height;

        data = Bytes.alloc(width * height);
    }

    public inline function getPixel(x:Int, y:Int):Int
    {
        if (x < 0 || x >= width)
        {
            return outsideIsSolid ? solid : empty;
        }

        if (y < 0 || y >= height)
        {
            return empty;
        }

        return data.get(y * width + x);
    }

    public inline function setPixel(x:Int, y:Int, material:Int)
    {
        if (x < 0 || y < 0 || x >= width || y >= height)
        {
            return;
        }

        data.set(y * width + x, material);
    }

    public inline function isSolid(x:Int, y:Int):Bool
    {
        var material = getPixel(x, y);

        return material == ground || material == solid;
    }

    public inline function isDiggable(x:Int, y:Int):Bool
    {
        return getPixel(x, y) == ground;
    }

    public function clear()
    {
        data.fill(0, data.length, empty);
    }
}