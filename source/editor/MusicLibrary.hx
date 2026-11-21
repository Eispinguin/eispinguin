package editor;

import haxe.Json;
import openfl.Assets;

class MusicTrack
{
    public var name:String;
    public var asset:String;

    public function new(name:String, asset:String)
    {
        this.name = name;
        this.asset = asset;
    }
}

class MusicLibrary
{
    public var tracks:Array<MusicTrack> = [];

    public function new()
    {
        tracks.push(new MusicTrack("No Music", ""));
    }

    public static function load(path:String):MusicLibrary
    {
        var library = new MusicLibrary();
        var root:Dynamic = Json.parse(Assets.getText(path));
        var entries:Array<Dynamic> = cast Reflect.field(root, "tracks");

        if (entries != null)
        {
            for (entry in entries)
            {
                var name = Std.string(entry.name);
                var asset = Std.string(entry.asset);

                if (asset == "")
                {
                    continue;
                }

                library.tracks.push(new MusicTrack(name, asset));
            }
        }

        return library;
    }

    public function findOrAdd(asset:String):Int
    {
        for (i in 0...tracks.length)
        {
            if (tracks[i].asset == asset)
            {
                return i;
            }
        }

        tracks.push(new MusicTrack("Custom Music", asset));

        return tracks.length - 1;
    }
}