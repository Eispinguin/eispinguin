package;

import lime.utils.Assets;

class Global
{
    public static var levels:Array<String>;

    public static function loadLevels()
    {
        levels = Assets.getText("assets/data/levels.txt").split("\n").map(StringTools.trim).filter(function(l) return l != "");
    }
}