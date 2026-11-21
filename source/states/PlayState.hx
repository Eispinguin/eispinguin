package states;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.util.FlxGradient;
import characters.Player;
import collision.GroundPiece;
import collision.TerrainManager;
import collision.TerrainPhysics;
import editor.EditorHistory;
import editor.LevelDocument;
import editor.LevelEditorState;
import flixel.FlxG;
import flixel.FlxState;
import flixel.system.FlxAssets;
import openfl.Assets;
import util.GroundPieceDefinition;

class PlayState extends FlxState
{
	var terrain:TerrainManager;
	var terrainPhysics:TerrainPhysics;

	var player:Player;

	var editorPlaytestJson:Null<String>;
	var editorLevelPath:Null<String>;
	var editorSavePath:Null<String>;
	var editorHistory:Null<editor.EditorHistory>;
	var isEditorPlaytest:Bool = false;
	var editorCurrentFilePath:Null<String>;

	var levelPath:String;

	var levelGradient:FlxSprite;

    var gradientTop:String = "";
    var gradientBottom:String = "";

	public function new(?levelPath:String, ?playtestJson:String, ?editorLevelPath:String, ?editorSavePath:String, ?editorHistory:EditorHistory, ?editorCurrentFilePath:String)
	{
		super();

		this.editorPlaytestJson = playtestJson;
		this.editorLevelPath = editorLevelPath;
		this.editorSavePath = editorSavePath;
		this.editorHistory = editorHistory;

		this.editorCurrentFilePath = editorCurrentFilePath;

		this.isEditorPlaytest = playtestJson != null;

		this.levelPath = levelPath == null ? Global.levels[0] : levelPath;
	}

	override public function create()
	{
		super.create();

        var groundpieceLibrary = GroundPieceLibrary.load("assets/data/groundpieces.json");
		var json = editorPlaytestJson != null ? editorPlaytestJson : Assets.getText(levelPath);
		var document = LevelDocument.fromJson(json);

		terrain = new TerrainManager(document.width, document.height);

		var pieces:Array<GroundPiece> = [];

		for (placement in document.pieces)
		{
			var definition = groundpieceLibrary.getById(placement.id);

			pieces.push(new GroundPiece(definition.bitmap, placement.x, placement.y, definition.type, definition.collisionMask));
		}

		addLevelGradient(document);

		terrain.addPieces(pieces);

		add(terrain.sprite);

		terrainPhysics = new TerrainPhysics(terrain);

		player = new Player(document.playerX, document.playerY, terrainPhysics);

		add(player);

		FlxG.camera.follow(player, PLATFORMER, 1.0);
		FlxG.camera.setScrollBoundsRect(0, 0, terrain.width, terrain.height, true);
		FlxG.worldBounds.set(0, 0, terrain.width, terrain.height);

		if (document.music != null && document.music != "")
		{
			FlxG.sound.playMusic(document.music, 1.0, true);
		}
		else if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// It's fun!
		if (FlxG.mouse.pressed)
        {
            terrain.digCircleWorld(FlxG.mouse.x, FlxG.mouse.y, 24);
        }

		#if sys
		if (FlxG.keys.justPressed.E)
		{
			FlxG.switchState(() -> new LevelEditorState("assets/data/levels/blank.json", "levels/level1.json"));
		}

		if (isEditorPlaytest && FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(() -> new editor.LevelEditorState(editorLevelPath, editorSavePath, editorPlaytestJson, editorHistory, editorCurrentFilePath));

			return;
		}
		#end
	}

	function addLevelGradient(document:LevelDocument)
    {
        var parsedTop = FlxColor.fromString(document.gradientTop);
        var parsedBottom = FlxColor.fromString(document.gradientBottom);

        var topColor:FlxColor = parsedTop == null ? 0x8080FF : cast parsedTop;
        var bottomColor:FlxColor = parsedBottom == null ? FlxColor.WHITE : cast parsedBottom;

        levelGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [topColor, bottomColor], 1, 90);

        levelGradient.scrollFactor.set(0, 0);

        add(levelGradient);
    }
}
