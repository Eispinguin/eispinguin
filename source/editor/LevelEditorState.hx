
package editor;

import collision.GroundPiece;
import collision.TerrainManager;
import editor.LevelDocument;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import openfl.Assets;
import openfl.geom.Rectangle;
import states.PlayState;
import util.GroundPieceDefinition;

class LevelEditorState extends FlxState
{
    static inline var resizeStep:Int = 64;
    static inline var minLevelSize:Int = 800;
    static inline var minLevelHeight:Int = 600;
    static inline var maxLevelSize:Int = 4096;

    static inline var playerWidth:Int = 8;
    static inline var playerHeight:Int = 18;

    static inline var cameraSpeed:Float = 500;

    static inline var paletteWidth:Int = 184;
    static inline var paletteHeight:Int = 240;
    static inline var paletteRows:Int = 8;

    public var levelAssetPath:String;
    public var savePath:String;

    var initialJson:Null<String>;

    var fileDialog:FileDialog;

    var currentFilePath:Null<String> = null;

    var document:LevelDocument;

    var groundpieceLibrary:GroundPieceLibrary;
    var musicLibrary:MusicLibrary;

    var history:EditorHistory;

    var terrain:TerrainManager;

    var playerMarker:FlxSprite;
    var selectionOutline:FlxSprite;

    var hud:FlxText;

    var paletteBackground:FlxSprite;
    var paletteText:FlxText;
    var palettePreview:FlxSprite;

    var tool:String = "place";

    var selectedPieceIndex:Int = 0;
    var selectedPlacementIndex:Int = -1;
    var selectedMusicIndex:Int = 0;

    var draggingPiece:Bool = false;
    var draggingPlayer:Bool = false;
    var dragPreview:FlxSprite;

    var dragStartX:Int = 0;
    var dragStartY:Int = 0;

    var dragTargetX:Int = 0;
    var dragTargetY:Int = 0;

    var dragOffsetX:Float = 0;
    var dragOffsetY:Float = 0;

    var dragChanged:Bool = false;

    var levelGradient:FlxSprite;

    var displayedGradientTop:String = "";
    var displayedGradientBottom:String = "";

    var objectLibrary:LevelObjectLibrary;

    var selectedObjectIndex:Int = 0;
    var selectedObjectPlacementIndex:Int = -1;

    var objectPaletteBackground:FlxSprite;
    var objectPaletteText:FlxText;
    var objectPalettePreview:FlxSprite;

    var objectSprites:Array<FlxSprite> = [];

    var draggingObject:Bool = false;

    public function new(levelAssetPath:String, savePath:String, ?initialJson:String, ?existingHistory:EditorHistory, ?currentFilePath:String)
    {
        super();

        this.levelAssetPath = levelAssetPath;
        this.savePath = savePath;

        this.initialJson = initialJson;
        this.history = existingHistory;

        this.currentFilePath = currentFilePath;
    }

    override public function create()
    {
        super.create();

        FlxG.mouse.visible = true;

        FlxG.camera.scroll.set(0, 0);

        groundpieceLibrary = GroundPieceLibrary.load("assets/data/groundpieces.json");
        musicLibrary = MusicLibrary.load("assets/data/music.json");
        objectLibrary = LevelObjectLibrary.load("assets/data/objects.json");

        var json = initialJson != null ? initialJson : Assets.getText(levelAssetPath);

        document = LevelDocument.fromJson(json);

        if (history == null)
        {
            history = new EditorHistory();
            history.reset(document.toJson());
        }

        selectedMusicIndex = musicLibrary.findOrAdd(document.music);

        terrain = new TerrainManager(document.width, document.height);

        rebuildTerrain();

        add(terrain.sprite);

        updateLevelGradient();

        dragPreview = new FlxSprite();

        dragPreview.alpha = 0.5;
        dragPreview.visible = false;

        add(dragPreview);

        rebuildObjects();

        playerMarker = new FlxSprite();
        playerMarker.loadGraphic("assets/images/engine/editor/player.png");

        add(playerMarker);

        selectionOutline = new FlxSprite();
        selectionOutline.visible = false;

        add(selectionOutline);

        hud = new FlxText(8, 8, FlxG.width - 16, "", 10);
        hud.scrollFactor.set(0, 0);

        add(hud);

        var paletteX = Math.max(4, FlxG.width - paletteWidth - 8);

        paletteBackground = new FlxSprite(paletteX, 200);
        paletteBackground.makeGraphic(paletteWidth, paletteHeight, 0x7F58B4FF, true);
        paletteBackground.scrollFactor.set(0, 0);

        add(paletteBackground);

        palettePreview = new FlxSprite();
        palettePreview.scrollFactor.set(0, 0);

        add(palettePreview);

        paletteText = new FlxText(paletteX + 8, 48, paletteWidth - 16, "", 10);
        paletteText.scrollFactor.set(0, 0);

        add(paletteText);

        objectPaletteBackground = new FlxSprite(8, 200);
        objectPaletteBackground.makeGraphic(paletteWidth, paletteHeight, 0x7F58B4FF, true);
        objectPaletteBackground.scrollFactor.set(0, 0);

        add(objectPaletteBackground);

        objectPalettePreview = new FlxSprite();
        objectPalettePreview.scrollFactor.set(0, 0);

        add(objectPalettePreview);

        objectPaletteText = new FlxText(16, 206, paletteWidth - 16, "", 10);
        objectPaletteText.scrollFactor.set(0, 0);

        add(objectPaletteText);

        updatePlayerMarker();
        refreshSelection();

        updatePalette();
        updateObjectPalette();
        updateHUD();

        updateCameraBounds();

        previewMusic();
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (handleKeyboard(elapsed))
        {
            return;
        }

        handleMouse();

        updateHUD();
    }

    function handleKeyboard(elapsed:Float):Bool
    {
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT)
        {
            if (FlxG.keys.justPressed.LEFT)
            {
                resizeLevel(-resizeStep, 0);
                return true;
            }

            if (FlxG.keys.justPressed.RIGHT)
            {
                resizeLevel(resizeStep, 0);
                return true;
            }

            if (FlxG.keys.justPressed.UP)
            {
                resizeLevel(0, -resizeStep);
                return true;
            }

            if (FlxG.keys.justPressed.DOWN)
            {
                resizeLevel(0, resizeStep);
                return true;
            }
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
        {
            undo();
            return true;
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y)
        {
            redo();
            return true;
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.O)
        {
            openLevelDialog();
            return true;
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.S)
        {
            saveAsDialog();
            return true;
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
        {
            save();
            return true;
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
        {
            save();
            return true;
        }

        if (FlxG.keys.justPressed.ENTER)
        {
            startPlaytest();
            return true;
        }

        if (FlxG.keys.justPressed.ONE)
        {
            setTool("place");
        }

        if (FlxG.keys.justPressed.TWO)
        {
            setTool("select");
        }

        if (FlxG.keys.justPressed.THREE)
        {
            setTool("player");
        }

        if (FlxG.keys.justPressed.FOUR)
        {
            setTool("object");
        }

        if (FlxG.keys.justPressed.Q)
        {
            cycleGroundpiece(-1);
        }

        if (FlxG.keys.justPressed.E)
        {
            cycleGroundpiece(1);
        }

        if (FlxG.keys.justPressed.Z)
        {
            cycleObject(-1);
        }

        if (FlxG.keys.justPressed.X)
        {
            cycleObject(1);
        }

        if (FlxG.keys.justPressed.DELETE)
        {
            deleteSelected();
        }

        if (FlxG.keys.justPressed.PAGEUP)
        {
            cycleMusic(-1);
        }

        if (FlxG.keys.justPressed.PAGEDOWN)
        {
            cycleMusic(1);
        }

        updateCamera(elapsed);

        return false;
    }

    function updateCameraBounds()
    {
        var maxX = Math.max(0, document.width - FlxG.camera.viewWidth);
        var maxY = Math.max(0, document.height - FlxG.camera.viewHeight);

        FlxG.camera.scroll.x = FlxG.camera.scroll.x < 0 ? 0 : Math.min(FlxG.camera.scroll.x, maxX);
        FlxG.camera.scroll.y = FlxG.camera.scroll.y < 0 ? 0 : Math.min(FlxG.camera.scroll.y, maxY);
    }

    function updateCamera(elapsed:Float)
    {
        var dx:Float = 0;
        var dy:Float = 0;

        if (FlxG.keys.pressed.LEFT)
        {
            dx -= 1;
        }

        if (FlxG.keys.pressed.RIGHT)
        {
            dx += 1;
        }

        if (FlxG.keys.pressed.UP)
        {
            dy -= 1;
        }

        if (FlxG.keys.pressed.DOWN)
        {
            dy += 1;
        }

        var speed = cameraSpeed;

        if (FlxG.keys.pressed.SHIFT)
        {
            speed *= 2;
        }

        FlxG.camera.scroll.x += dx * speed * elapsed;
        FlxG.camera.scroll.y += dy * speed * elapsed;

        updateCameraBounds();
    }

    function resizeLevel(deltaWidth:Int, deltaHeight:Int)
    {
        var requestedHeight = document.height + deltaHeight;

        if (deltaHeight < 0 && requestedHeight < minLevelHeight)
        {
            trace("Levels can't be shorter than " + minLevelHeight + " pixels!");
            
            return;
        }

        var newWidth = Std.int(Math.max(minLevelSize, Math.min(maxLevelSize, document.width + deltaWidth)));
        var newHeight = Std.int(Math.max(minLevelSize, Math.min(maxLevelSize, requestedHeight)));

        if (newWidth == document.width && newHeight == document.height)
        {
            return;
        }

        document.width = newWidth;
        document.height = newHeight;

        syncTerrainToDocument();

        history.push(document.toJson());

        updateHUD();
    }

    function syncTerrainToDocument()
    {
        updateLevelGradient();

        if (terrain.width != document.width || terrain.height != document.height)
        {
            var oldSprite = terrain.sprite;
            var terrainIndex = members.indexOf(oldSprite);

            remove(oldSprite, true);
            terrain.destroy();

            terrain = new TerrainManager(document.width, document.height);

            if (terrainIndex < 0)
            {
                terrainIndex = 0;
            }

            insert(terrainIndex, terrain.sprite);
        }

        rebuildTerrain();
        rebuildObjects();
        updateCameraBounds();
    }

    function handleMouse():Void
    {
        var mx = Std.int(Math.floor(FlxG.mouse.x));
        var my = Std.int(Math.floor(FlxG.mouse.y));

        if (FlxG.mouse.justPressed)
        {
            if (mouseOverPalette())
            {
                return;
            }

            switch (tool)
            {
                case "place":
                    placeGroundpiece(mx, my);

                case "select":
                    if (selectObject(mx, my))
                    {
                        startObjectDrag(mx, my);
                    }
                    else
                    {
                        selectGroundpiece(mx, my);

                        if (selectedPlacementIndex >= 0)
                        {
                            var placement = document.pieces[selectedPlacementIndex];
                            var definition = groundpieceLibrary.getById(placement.id);

                            dragStartX = placement.x;
                            dragStartY = placement.y;

                            dragTargetX = placement.x;
                            dragTargetY = placement.y;

                            dragOffsetX = mx - placement.x;
                            dragOffsetY = my - placement.y;

                            draggingPiece = true;
                            dragChanged = false;

                            dragPreview.loadGraphic(definition.bitmap, false, 0, 0, true);

                            dragPreview.alpha = 0.5;
                            dragPreview.x = placement.x;
                            dragPreview.y = placement.y;
                            dragPreview.visible = true;
                        }
                    }

                case "player":
                    draggingPlayer = true;
                    dragChanged = false;

                    dragOffsetX = playerMarker.width / 2;
                    dragOffsetY = playerMarker.height / 2;

                    updatePlayerDrag(mx, my);
                
                case "object":
                    placeObject(mx, my);
            }
        }

        if (FlxG.mouse.pressed)
        {
            if (draggingPiece)
            {
                updatePieceDrag(mx, my);
            }

            if (draggingPlayer)
            {
                updatePlayerDrag(mx, my);
            }

            if (draggingObject)
            {
                updateObjectDrag(mx, my);
            }
        }

        if (FlxG.mouse.justReleased)
        {
            if (draggingPiece)
            {
                updatePieceDrag(mx, my);

                finishPieceDrag();
            }

            if (draggingPlayer)
            {
                updatePlayerDrag(mx, my);

                draggingPlayer = false;

                if (dragChanged)
                {
                    commitEdit(false);
                }
            }

            if (draggingObject)
            {
                updateObjectDrag(mx, my);
                finishObjectDrag();
            }
        }
    }

    function mouseOverPalette():Bool
    {
        var x = FlxG.mouse.viewX;
        var y = FlxG.mouse.viewY;

        var overGroundpiecePalette = x >= FlxG.width - paletteWidth - 8 && x <= FlxG.width - 8 && y >= 42 && y <= 42 + paletteHeight;
        var overObjectPalette = x >= 8 && x <= 8 + paletteWidth && y >= 200 && y <= 200 + paletteHeight;

        return overGroundpiecePalette || overObjectPalette;
    }

    function placeGroundpiece(x:Int, y:Int)
    {
        if (groundpieceLibrary.definitions.length == 0)
        {
            return;
        }

        var definition = groundpieceLibrary.definitions[selectedPieceIndex];

        document.pieces.push(new LevelPiecePlacement(definition.id, x, y));
        selectedPlacementIndex = document.pieces.length - 1;

        commitEdit();
    }

    function placeObject(x:Int, y:Int)
    {
        if (objectLibrary.definitions.length == 0)
        {
            return;
        }

        var definition = objectLibrary.definitions[selectedObjectIndex];

        document.objects.push(new ObjectPlacement(definition.id, x, y));

        selectedObjectPlacementIndex = document.objects.length - 1;
        selectedPlacementIndex = -1;

        commitEdit();
    }

    function selectGroundpiece(x:Int, y:Int)
    {
        selectedPlacementIndex = -1;
        selectedObjectPlacementIndex = -1;

        for (i in 0...document.pieces.length)
        {
            var index = document.pieces.length - 1 - i;

            var placement = document.pieces[index];

            var definition = groundpieceLibrary.getById(placement.id);

            var localX = x - placement.x;
            var localY = y - placement.y;

            if (localX < 0 || localY < 0 || localX >= definition.bitmap.width || localY >= definition.bitmap.height)
            {
                continue;
            }

            var pixel = definition.bitmap.getPixel32(localX, localY);
            var alpha = (pixel >>> 24) & 0xFF;

            if (alpha > 0)
            {
                selectedPlacementIndex = index;
                break;
            }
        }

        refreshSelection();
    }

    function selectObject(x:Int, y:Int):Bool
    {
        selectedObjectPlacementIndex = -1;
        selectedPlacementIndex = -1;

        for (i in 0...document.objects.length)
        {
            var index = document.objects.length - 1 - i;
            var placement = document.objects[index];
            var definition = objectLibrary.getById(placement.id);

            var localX = x - placement.x;
            var localY = y - placement.y;

            if (localX < 0 || localY < 0 || localX >= definition.bitmap.width || localY >= definition.bitmap.height)
            {
                continue;
            }

            var pixel = definition.bitmap.getPixel32(localX, localY);
            var alpha = (pixel >>> 24) & 0xFF;

            if (alpha > 0)
            {
                selectedObjectPlacementIndex = index;
                break;
            }
        }

        refreshSelection();

        return selectedObjectPlacementIndex >= 0;
    }

    function updatePieceDrag(mouseX:Int, mouseY:Int)
    {
        if (selectedPlacementIndex < 0 || selectedPlacementIndex >= document.pieces.length)
        {
            return;
        }

        var newX = Std.int(Math.floor(mouseX - dragOffsetX));
        var newY = Std.int(Math.floor(mouseY - dragOffsetY));

        dragTargetX = newX;
        dragTargetY = newY;

        dragChanged = dragTargetX != dragStartX || dragTargetY != dragStartY;

        dragPreview.x = dragTargetX;
        dragPreview.y = dragTargetY;

        selectionOutline.x = dragTargetX;
        selectionOutline.y = dragTargetY;
    }

    function updatePlayerDrag(mouseX:Int, mouseY:Int)
    {
        var newX = Math.floor(mouseX - dragOffsetX);
        var newY = Math.floor(mouseY - dragOffsetY);

        if (document.playerX == newX && document.playerY == newY)
        {
            return;
        }

        document.playerX = newX;
        document.playerY = newY;

        dragChanged = true;

        updatePlayerMarker();
    }

    function startObjectDrag(mouseX:Int, mouseY:Int)
    {
        var placement = document.objects[selectedObjectPlacementIndex];
        var definition = objectLibrary.getById(placement.id);

        dragStartX = placement.x;
        dragStartY = placement.y;

        dragTargetX = placement.x;
        dragTargetY = placement.y;

        dragOffsetX = mouseX - placement.x;
        dragOffsetY = mouseY - placement.y;

        draggingObject = true;
        dragChanged = false;

        dragPreview.loadGraphic(definition.bitmap, false, 0, 0, true);

        dragPreview.alpha = 0.5;
        dragPreview.x = placement.x;
        dragPreview.y = placement.y;
        dragPreview.visible = true;

        if (selectedObjectPlacementIndex < objectSprites.length)
        {
            objectSprites[selectedObjectPlacementIndex].visible = false;
        }
    }

    function updateObjectDrag(mouseX:Int, mouseY:Int)
    {
        if (selectedObjectPlacementIndex < 0 || selectedObjectPlacementIndex >= document.objects.length)
        {
            return;
        }

        var newX = Std.int(Math.floor(mouseX - dragOffsetX));
        var newY = Std.int(Math.floor(mouseY - dragOffsetY));

        dragTargetX = newX;
        dragTargetY = newY;

        dragChanged = dragTargetX != dragStartX || dragTargetY != dragStartY;

        dragPreview.x = dragTargetX;
        dragPreview.y = dragTargetY;

        selectionOutline.x = dragTargetX;
        selectionOutline.y = dragTargetY;
    }

    function finishObjectDrag()
    {
        draggingObject = false;
        dragPreview.visible = false;

        if (!dragChanged)
        {
            if (selectedObjectPlacementIndex >= 0 && selectedObjectPlacementIndex < objectSprites.length)
            {
                objectSprites[selectedObjectPlacementIndex].visible = true;
            }

            updateSelectionPosition();
            return;
        }

        if (selectedObjectPlacementIndex < 0 || selectedObjectPlacementIndex >= document.objects.length)
        {
            return;
        }

        var placement = document.objects[selectedObjectPlacementIndex];

        placement.x = dragTargetX;
        placement.y = dragTargetY;

        rebuildObjects();

        commitEdit(false);

        dragChanged = false;
    }

    function updatePlayerMarker()
    {
        playerMarker.x = document.playerX;
        playerMarker.y = document.playerY;
    }

    function deleteSelected()
    {
        if (selectedPlacementIndex < 0 || selectedPlacementIndex >= document.pieces.length)
        {
            return;
        }

        if (selectedObjectPlacementIndex >= 0 && selectedObjectPlacementIndex < document.objects.length)
        {
            document.objects.splice(selectedObjectPlacementIndex, 1);

            selectedObjectPlacementIndex = -1;

            commitEdit();

            return;
        }

        document.pieces.splice(selectedPlacementIndex, 1);
        selectedPlacementIndex = -1;

        commitEdit();
    }

    function setTool(newTool:String)
    {
        tool = newTool;

        draggingPiece = false;
        draggingPlayer = false;
        draggingObject = false;

        updateHUD();
    }

    function cycleGroundpiece(direction:Int)
    {
        var count = groundpieceLibrary.definitions.length;

        if (count == 0)
        {
            return;
        }

        selectedPieceIndex += direction;

        if (selectedPieceIndex < 0)
        {
            selectedPieceIndex = count - 1;
        }

        if (selectedPieceIndex >= count)
        {
            selectedPieceIndex = 0;
        }

        updatePalette();
    }

    function cycleObject(direction:Int)
    {
        var count = objectLibrary.definitions.length;

        if (count == 0)
        {
            return;
        }

        selectedObjectIndex += direction;

        if (selectedObjectIndex < 0)
        {
            selectedObjectIndex = count - 1;
        }

        if (selectedObjectIndex >= count)
        {
            selectedObjectIndex = 0;
        }

        updateObjectPalette();
    }

    function updatePalette()
    {
        var definitions = groundpieceLibrary.definitions;

        if (definitions.length == 0)
        {
            paletteText.text = "GROUNDPIECES\nNo pieces loaded";
            palettePreview.visible = false;
            return;
        }

        var start = Std.int(Math.max(0, selectedPieceIndex - Std.int(paletteRows / 2)));
        start = Std.int(Math.min(start, Math.max(0, definitions.length - paletteRows)));

        var end = Std.int(Math.min(definitions.length, start + paletteRows));

        var lines:Array<String> = [];

        lines.push("GROUNDPIECES");
        lines.push("Q / E to select");
        lines.push("");

        for (i in start...end)
        {
            var definition = definitions[i];

            var marker = i == selectedPieceIndex ? "> " : "  ";

            lines.push(marker + definition.name);
        }

        paletteText.text = lines.join("\n");

        var selectedDefinition = definitions[selectedPieceIndex];

        palettePreview.loadGraphic(selectedDefinition.bitmap, false, 0, 0, true);

        var maxWidth = paletteWidth - 20;
        var maxHeight = 55;

        var scale = Math.min(1, Math.min(maxWidth / selectedDefinition.bitmap.width, maxHeight / selectedDefinition.bitmap.height));

        var previewWidth = Std.int(selectedDefinition.bitmap.width * scale);
        var previewHeight = Std.int(selectedDefinition.bitmap.height * scale);

        palettePreview.setGraphicSize(previewWidth, previewHeight);
        palettePreview.updateHitbox();

        palettePreview.x = FlxG.width - previewWidth - 8 + (previewWidth - palettePreview.width) / 2;

        palettePreview.y = 200 + paletteHeight - palettePreview.height - 8;

        palettePreview.visible = true;
    }

    function updateObjectPalette()
    {
        var definitions = objectLibrary.definitions;

        if (definitions.length == 0)
        {
            objectPaletteText.text = "Objects: \nNo objects loaded";
            objectPalettePreview.visible = false;
            return;
        }

        var lines:Array<String> = [];

        lines.push("Objects");
        lines.push("Z / X to cycle through / select");
        lines.push("");

        for (i in 0...definitions.length)
        {
            var definition = definitions[i];

            var marker = i == selectedObjectIndex ? "> " : "  ";

            lines.push(marker + definition.name);
        }

        objectPaletteText.text = lines.join("\n");

        var selectedDefinition = definitions[selectedObjectIndex];

        objectPalettePreview.loadGraphic(selectedDefinition.bitmap, false, 0, 0, true);

        var maxWidth = paletteWidth - 20;
        var maxHeight = 55;

        var scale = Math.min(1, Math.min(maxWidth / selectedDefinition.bitmap.width, maxHeight / selectedDefinition.bitmap.height));

        var previewWidth = Std.int(selectedDefinition.bitmap.width * scale);
        var previewHeight = Std.int(selectedDefinition.bitmap.height * scale);

        objectPalettePreview.setGraphicSize(previewWidth, previewHeight);
        objectPalettePreview.updateHitbox();

        objectPalettePreview.x = 8 + (paletteWidth - previewWidth) / 2;
        objectPalettePreview.y = 200 + paletteHeight - previewHeight - 8;

        objectPalettePreview.visible = true;
    }

    function refreshSelection()
    {
        if (selectionOutline == null)
        {
            return;
        }

        var w:Int;
        var h:Int;

        if (selectedObjectPlacementIndex >= 0 && selectedObjectPlacementIndex < document.objects.length)
        {
            var placement = document.objects[selectedObjectPlacementIndex];
            var definition = objectLibrary.getById(placement.id);

            w = definition.bitmap.width;
            h = definition.bitmap.height;
        }
        else if (selectedPlacementIndex >= 0 && selectedPlacementIndex < document.pieces.length)
        {
            var placement = document.pieces[selectedPlacementIndex];
            var definition = groundpieceLibrary.getById(placement.id);

            w = definition.bitmap.width;
            h = definition.bitmap.height;
        }
        else
        {
            selectionOutline.visible = false;
            return;
        }

        selectionOutline.makeGraphic(w, h, FlxColor.TRANSPARENT, true);

        var pixels = selectionOutline.pixels;
        var thickness = 2;

        pixels.fillRect(new Rectangle(0, 0, w, thickness), FlxColor.CYAN);
        pixels.fillRect(new Rectangle(0, h - thickness, w, thickness), FlxColor.CYAN);
        pixels.fillRect(new Rectangle(0, 0, thickness, h), FlxColor.CYAN);
        pixels.fillRect(new Rectangle(w - thickness, 0, thickness, h), FlxColor.CYAN);

        selectionOutline.dirty = true;

        updateSelectionPosition();

        selectionOutline.visible = true;
    }

    function updateSelectionPosition()
    {
        if (selectedObjectPlacementIndex >= 0 && selectedObjectPlacementIndex < document.objects.length)
        {
            var placement = document.objects[selectedObjectPlacementIndex];

            selectionOutline.x = placement.x;
            selectionOutline.y = placement.y;
        }
        else if (selectedPlacementIndex >= 0 && selectedPlacementIndex < document.pieces.length)
        {
            var placement = document.pieces[selectedPlacementIndex];

            selectionOutline.x = placement.x;
            selectionOutline.y = placement.y;
        }
    }

    function cycleMusic(direction:Int)
    {
        var count = musicLibrary.tracks.length;

        if (count == 0)
        {
            return;
        }

        selectedMusicIndex += direction;

        if (selectedMusicIndex < 0)
        {
            selectedMusicIndex = count - 1;
        }

        if (selectedMusicIndex >= count)
        {
            selectedMusicIndex = 0;
        }

        document.music = musicLibrary.tracks[selectedMusicIndex].asset;

        previewMusic();

        commitEdit(false);
    }

    function previewMusic()
    {
        if (document.music == null || document.music == "")
        {
            if (FlxG.sound.music != null)
            {
                FlxG.sound.music.stop();
            }

            return;
        }

        FlxG.sound.playMusic(document.music, 1, true);
    }

    function rebuildTerrain()
    {
        var pieces:Array<GroundPiece> = [];

        for (placement in document.pieces)
        {
            var definition = groundpieceLibrary.getById(placement.id);

            pieces.push(new GroundPiece(definition.bitmap, placement.x, placement.y, definition.type, definition.collisionMask));
        }

        terrain.replacePieces(pieces);
    }

    function rebuildObjects():Void
    {
        for (sprite in objectSprites)
        {
            remove(sprite, true);
        }

        objectSprites = [];

        var insertIndex = members.indexOf(dragPreview);

        if (insertIndex < 0)
        {
            insertIndex = members.length;
        }

        for (placement in document.objects)
        {
            var definition = objectLibrary.getById(placement.id);

            var sprite = new FlxSprite(placement.x, placement.y);

            sprite.loadGraphic(definition.bitmap, false, 0, 0, true);

            objectSprites.push(sprite);

            insert(insertIndex, sprite);
            insertIndex += 1;
        }
    }

    function commitEdit(rebuild:Bool = true)
    {
        history.push(document.toJson());

        if (rebuild)
        {
            syncTerrainToDocument();
        }

        updatePlayerMarker();
        refreshSelection();
        updateHUD();
    }

    function undo()
    {
        var snapshot = history.undo();

        if (snapshot == null)
        {
            return;
        }

        restoreDocument(snapshot);
    }

    function redo()
    {
        var snapshot = history.redo();

        if (snapshot == null)
        {
            return;
        }

        restoreDocument(snapshot);
    }

    function restoreDocument(snapshot:String)
    {
        document = LevelDocument.fromJson(snapshot);

        selectedPlacementIndex = -1;

        selectedMusicIndex = musicLibrary.findOrAdd(document.music);

        syncTerrainToDocument();
        updatePlayerMarker();
        refreshSelection();
        updatePalette();
        previewMusic();
        updateHUD();
    }

    function startPlaytest()
    {
        var snapshot = document.toJson();

        FlxG.switchState(() -> new PlayState(null, snapshot, levelAssetPath, savePath, history, currentFilePath));
    }

    function updateHUD()
    {
        var pieceName = "None";

        if (groundpieceLibrary.definitions.length > 0)
        {
            pieceName = groundpieceLibrary.definitions[selectedPieceIndex].name;
        }

        var objectName = "None";

        if (objectLibrary.definitions.length > 0)
        {
            objectName = objectLibrary.definitions[selectedObjectIndex].name;
        }

        var musicName = "No Music";

        if (musicLibrary.tracks.length > 0)
        {
            musicName = musicLibrary.tracks[selectedMusicIndex].name;
        }

        hud.text = "Tool: " + tool + " | Piece: " + pieceName + " | Music: " + musicName +
        "\n1: Place Ground, 2: Select/Drag, 3: Move Player, 4: Place Object" +
        "\nQ/E: Switch Pieces, Z/X: Switch Objects, Delete: Remove, Ctrl+Z/Y: Undo/Redo" +
        "\nCtrl+S: Save, ENTER: Playtest" +
        "\nArrows: Camera, Shift+Arrows: Fast Camera" +
        "\nCtrl+Shift+Arrows: Resize (32px) (Up = Decrease, Down = Increase)" +
        "\nCtrl+O: Open, Ctrl+S: Save, Ctrl+Shift+S: Save As";
    }

    function finishPieceDrag()
    {
        draggingPiece = false;

        dragPreview.visible = false;

        if (!dragChanged)
        {
            updateSelectionPosition();
            return;
        }

        if (selectedPlacementIndex < 0 || selectedPlacementIndex >= document.pieces.length)
        {
            return;
        }

        var placement = document.pieces[selectedPlacementIndex];

        terrain.movePiece(selectedPlacementIndex, dragTargetX, dragTargetY);

        placement.x = dragTargetX;
        placement.y = dragTargetY;

        history.push(document.toJson());

        refreshSelection();
        updateHUD();

        dragChanged = false;
    }

    override public function destroy()
    {
        if (terrain != null)
        {
            remove(terrain.sprite, true);
            terrain.destroy();
        }

        super.destroy();
    }

    function openLevelDialog()
    {
        #if sys
        fileDialog = new FileDialog();

        fileDialog.onSelect.add(function(path:String)
        {
            fileDialog = null;

            loadLevelFromPath(path);
        });

        fileDialog.onCancel.add(function()
        {
            fileDialog = null;
        });

        var opened = fileDialog.browse(FileDialogType.OPEN, "json", savePath, "Open Level");

        if (!opened)
        {
            fileDialog = null;
            trace("File browser is not supported on this platform!");
        }
        #else
        trace("Opening files from a path requires a desktop build! How did you even get here?");
        #end
    }

    function loadLevelFromPath(path:String)
    {
        #if sys
        try
        {
            var json = sys.io.File.getContent(path);
            var loadedDocument = LevelDocument.fromJson(json);

            if (loadedDocument.width < 1 || loadedDocument.height < 1)
            {
                throw "Invalid level dimensions!";
            }

            for (placement in loadedDocument.pieces)
            {
                groundpieceLibrary.getById(placement.id);
            }

            document = loadedDocument;

            currentFilePath = path;
            levelAssetPath = path;
            savePath = path;

            history.reset(document.toJson());

            selectedPlacementIndex = -1;

            draggingPiece = false;
            draggingPlayer = false;

            dragChanged = false;

            selectedMusicIndex = musicLibrary.findOrAdd(document.music);

            syncTerrainToDocument();
            updatePlayerMarker();
            refreshSelection();
            updatePalette();

            FlxG.camera.scroll.set(0, 0);

            updateCameraBounds();
            previewMusic();
            updateHUD();

            trace("Loaded level: " + path);
        }
        catch (error:Dynamic)
        {
            trace("Failed to load level: " + path + ": " + error);
        }

        #else
        trace("File loading is unavailable on this platform! How did you even get here?");
        #end
    }

    function save()
    {
        if (currentFilePath != null && currentFilePath != "")
        {
            saveToPath(currentFilePath);
        }
        else
        {
            saveAsDialog();
        }
    }

    function saveAsDialog()
    {
        #if sys
        fileDialog = new FileDialog();

        fileDialog.onSelect.add(function(path:String)
        {
            fileDialog = null;

            var finalPath = path;

            if (!StringTools.endsWith(finalPath.toLowerCase(), ".json"))
            {
                finalPath += ".json";
            }

            saveToPath(finalPath);
        });

        fileDialog.onCancel.add(function()
        {
            fileDialog = null;
        });

        var opened = fileDialog.browse(FileDialogType.SAVE, "json", savePath, "Save Level As");

        if (!opened)
        {
            fileDialog = null;
            trace("File browser is not supported on this platform!");
        }
        #else
        trace("File saving requires a desktop build! How did you even get here?");
        #end
    }

    function saveToPath(path:String):Void
    {
        #if sys
        try
        {
            var json = document.toJson();

            sys.io.File.saveContent(path, json);

            currentFilePath = path;
            savePath = path;
            levelAssetPath = path;

            updateHUD();

            trace("Saved level: " + path);
        }
        catch (error:Dynamic)
        {
            trace("Failed to save level: " + path + ": " + error);
        }
        #else
        trace("File saving requires a desktop build! How did you even get here?");
        #end
    }

    function updateLevelGradient()
    {
        if (levelGradient != null && displayedGradientBottom == document.gradientBottom && displayedGradientTop == document.gradientTop)
        {
            return;
        }

        if (levelGradient != null)
        {
            remove(levelGradient, true);
        }

        var parsedTop = FlxColor.fromString(document.gradientTop);
        var parsedBottom = FlxColor.fromString(document.gradientBottom);

        var topColor:FlxColor = parsedTop == null ? 0x45C4FF : cast parsedTop;
        var bottomColor:FlxColor = parsedBottom == null ? FlxColor.WHITE : cast parsedBottom;

        levelGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [topColor, bottomColor], 1, 90);

        levelGradient.scrollFactor.set(0, 0);

        displayedGradientTop = document.gradientTop;
        displayedGradientBottom = document.gradientBottom;

        insert(0, levelGradient);
    }
}