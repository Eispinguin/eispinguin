package characters;

import collision.TerrainPhysics;
import eispinguin.EPSprite;
import flixel.FlxG;
import flixel.FlxSprite;

class Player extends EPSprite
{
    // Movement
    public var walkSpeed:Float = 170;
    public var groundAcceleration:Float = 900;
    public var groundDeceleration:Float = 1100;
    public var jumpSpeed:Float = 500;
    public var coyoteDuration:Float = 0.12;
    public var jumpBufferDuration:Float = 0.12;
    public var jumpCutMultiplier:Float = 0.45;
    var jumpWasHeld:Bool = false;
    var jumpCutApplied:Bool = false;

    // Timers (don't change!)
    var coyoteTimer:Float = 0;
    var jumpBufferTimer:Float = 0;

    public function new(x:Float, y:Float, physics:TerrainPhysics)
    {
        super(x, y, physics);

        loadGraphic("assets/images/characters/eispe.png", true, 15, 25);
        animation.add("stand", [0], 15.0, false);
        animation.add("walk", [1, 2, 3, 4, 5, 6, 7, 8], 15.0, true);
        animation.add("duck", [9], 15.0, false);
        animation.add("jump", [10], 15.0, false);
        animation.add("skid", [11], 15.0, false);

        setSize(8, 18);
        offset.set(4, 7);

        velocity.set(0, 0);
        acceleration.set(0, 0);
        drag.set(0, 0);

        onGround = physics.isGrounded(this, 2);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        // Movement below!

        if (y > Global.PS.terrain.height)
        {
            killPlayer();
        }

        var direction:Int = 0;

        if (FlxG.keys.pressed.LEFT)
        {
            direction = -1;
            flipX = true;
        }

        if (FlxG.keys.pressed.RIGHT)
        {
            direction = 1;
            flipX = false;
        }

        var targetVelocityX = direction * walkSpeed;

        if (direction != 0)
        {
            velocityX = approach(velocityX, targetVelocityX, groundAcceleration * elapsed);
        }
        else
        {
            velocityX = approach(velocityX, 0, groundDeceleration * elapsed);
        }

        var touchingGround = physics.isGrounded(this, 2);

        onGround = touchingGround;

        if (touchingGround)
        {
            coyoteTimer = coyoteDuration;
        }
        else if (coyoteTimer > 0)
        {
            coyoteTimer -= elapsed;

            if (coyoteTimer < 0)
            {
                coyoteTimer = 0;
            }
        }

        var jumpHeld = FlxG.keys.pressed.SPACE;
        var jumpPressed = FlxG.keys.justPressed.SPACE;

        if (jumpPressed)
        {
            jumpBufferTimer = jumpBufferDuration;
        }
        else if (jumpBufferTimer > 0)
        {
            jumpBufferTimer -= elapsed;

            if (jumpBufferTimer < 0)
            {
                jumpBufferTimer = 0;
            }
        }

        if (jumpBufferTimer > 0 && coyoteTimer > 0)
        {
            velocityY = -jumpSpeed;

            jumpBufferTimer = 0;
            coyoteTimer = 0;

            onGround = false;

            jumpCutApplied = false;

            if (!jumpHeld)
            {
                velocityY *= jumpCutMultiplier;
                jumpCutApplied = true;
            }
        }

        if (jumpWasHeld && !jumpHeld && velocityY < 0 && !jumpCutApplied)
        {
            velocityY *= jumpCutMultiplier;

            jumpCutApplied = true;
        }

        jumpWasHeld = jumpHeld;

        var result = physics.move(this, velocityX, velocityY, elapsed);

        velocityX = result.velocityX;
        velocityY = result.velocityY;

        onGround = result.grounded;

        hittingCeiling = result.hitCeiling;
        touchingWall = result.hitWall;
        walkingIntoWall = result.hitWall && direction != 0;

        if (onGround)
        {
            coyoteTimer = coyoteDuration;
        }

        // Animation below!

        if (onGround)
        {
            if (velocityX == 0 || walkingIntoWall)
            {
                playAnimation("stand");
            }
            else if (velocityX != 0 && !walkingIntoWall)
            {
                playAnimation("walk");
            }
        }
        else
        {
            playAnimation("jump");
        }
    }

    function killPlayer()
    {
        FlxG.resetState();
    }
}