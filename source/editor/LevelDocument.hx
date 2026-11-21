package editor;

import haxe.Json;

class LevelPiecePlacement
{
    public var id:String;
    public var x:Int;
    public var y:Int;

    public function new(id:String, x:Int, y:Int)
    {
        this.id = id;
        this.x = x;
        this.y = y;
    }
}

class LevelDocument
{
    public var width:Int;
    public var height:Int;

    public var playerX:Float = 64;
    public var playerY:Float = 64;

    public var music:String = "";

    public var gradientTop:String = "0x8080FF";
    public var gradientBottom:String = "0xFFFFFF";

    public var pieces:Array<LevelPiecePlacement> = [];

    public function new(width:Int, height:Int)
    {
        this.width = width;
        this.height = height;
    }

    public static function fromJson(content:String):LevelDocument
    {
        var root:Dynamic = Json.parse(content);
        var document = new LevelDocument(Std.int(root.width), Std.int(root.height));
        var player:Dynamic = Reflect.field(root, "player");

        if (player != null)
        {
            document.playerX = player.x;
            document.playerY = player.y;
        }

        var music:Dynamic = Reflect.field(root, "music");

        if (music != null) 
        {
            document.music = Std.string(music);
        }

        var gradientTop:Dynamic = Reflect.field(root, "gradientTop");
        var gradientBottom:Dynamic = Reflect.field(root, "gradientBottom");

        if (gradientTop != null)
        {
            document.gradientTop = Std.string(gradientTop);
        }

        if (gradientBottom != null)
        {
            document.gradientBottom = Std.string(gradientBottom);
        }

        var entries:Array<Dynamic> = cast Reflect.field(root, "pieces");

        if (entries != null)
        {
            for (entry in entries)
            {
                document.pieces.push(new LevelPiecePlacement(Std.string(entry.id), Std.int(entry.x), Std.int(entry.y)));
            }
        }

        return document;
    }

    public function toJson():String
    {
        var pieceData:Array<Dynamic> = [];

        for (piece in pieces)
        {
            pieceData.push({id: piece.id, x: piece.x, y: piece.y});
        }

        return Json.stringify({width: width, height: height, player: {x: playerX, y: playerY}, music: music, pieces: pieceData, gradientTop: gradientTop, gradientBottom: gradientBottom}, null, "  ");
    }
}