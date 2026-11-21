package states;

import characters.Player;
import collision.GroundPiece;
import collision.TerrainManager;
import collision.TerrainPhysics;
import editor.EditorHistory;
import editor.LevelDocument;
import editor.LevelEditorState;
import editor.LevelObjectLibrary;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import objects.Goal;
import openfl.Assets;
import util.GroundPieceDefinition;

class PlayState extends FlxState
{
	public var terrain:TerrainManager;
	var terrainPhysics:TerrainPhysics;

	var player:Player;

	public var entities:FlxTypedGroup<FlxObject>;

	public var editorPlaytestJson:Null<String>;
	public var editorLevelPath:Null<String>;
	public var editorSavePath:Null<String>;
	public var editorHistory:Null<editor.EditorHistory>;
	public var editorPlaytest:Bool = false;
	public var editorCurrentFilePath:Null<String>;

	var levelPath:String;

	var levelGradient:FlxSprite;

    var gradientTop:String = "";
    var gradientBottom:String = "";

	public function new(?levelPath:String, ?playtestJson:String, ?editorLevelPath:String, ?editorSavePath:String, ?editorHistory:EditorHistory, ?editorCurrentFilePath:String)
	{
		super();

		Global.PS = this;

		this.editorPlaytestJson = playtestJson;
		this.editorLevelPath = editorLevelPath;
		this.editorSavePath = editorSavePath;
		this.editorHistory = editorHistory;

		this.editorCurrentFilePath = editorCurrentFilePath;

		this.editorPlaytest = playtestJson != null;

		this.levelPath = levelPath == null ? Global.levels[Global.currentLevel] : levelPath;
	}

	override public function create()
	{
		super.create();

        var groundpieceLibrary = GroundPieceLibrary.load("assets/data/groundpieces.json");
		var objectLibrary = LevelObjectLibrary.load("assets/data/objects.json");
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

		entities = new FlxTypedGroup<FlxObject>();

		for (placement in document.objects)
		{
			var definition = objectLibrary.getById(placement.id);

			switch (definition.id)
			{
				case "goal":
					entities.add(new Goal(placement.x + 33, placement.y));

				default:
					trace("Object unimplemented: " + placement.id);
			}
		}

		player = new Player(document.playerX, document.playerY, terrainPhysics);

		add(entities);
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

		if (editorPlaytest && FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(() -> new LevelEditorState(editorLevelPath, editorSavePath, editorPlaytestJson, editorHistory, editorCurrentFilePath));

			return;
		}

		FlxG.overlap(player, entities, collideEntities);
	}

	function collideEntities(player:Player, entity:FlxObject)
	{
		if (Std.isOfType(entity, Goal))
		{
			(cast entity).reach(player);
		}
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
