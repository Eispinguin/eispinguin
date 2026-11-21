package editor;

import haxe.Json;
import openfl.Assets;
import openfl.display.BitmapData;

class LevelObjectDefinition
{
    public var id:String;
    public var name:String;
    public var image:String;
    public var bitmap:BitmapData;

    public function new(id:String, name:String, image:String, bitmap:BitmapData)
    {
        this.id = id;
        this.name = name;
        this.image = image;
        this.bitmap = bitmap;
    }
}

class LevelObjectLibrary
{
    public var definitions:Array<LevelObjectDefinition> = [];

    public function new()
    {
    }

    public static function load(path:String):LevelObjectLibrary
    {
        var library = new LevelObjectLibrary();

        var root:Dynamic = Json.parse(Assets.getText(path));
        var entries:Array<Dynamic> = cast Reflect.field(root, "objects");

        if (entries != null)
        {
            for (entry in entries)
            {
                var id = Std.string(entry.id);
                var name = Std.string(entry.name);
                var image = Std.string(entry.image);

                var bitmap = Assets.getBitmapData(image);

                library.definitions.push(new LevelObjectDefinition(id, name, image, bitmap));
            }
        }

        return library;
    }

    public function getById(id:String):LevelObjectDefinition
    {
        for (definition in definitions)
        {
            if (definition.id == id)
            {
                return definition;
            }
        }

        throw "Unknown object ID: " + id;
    }
}