class Paddle
    constructor: (@config) ->
        if (@config.debug)
            console.log "initializing Paddle"

        @context = @config.context
        @canvas = @config.canvas

        @move_amount = @config.move_amount || (@canvas.width / 32)

        @width = @config.width || (@canvas.width / 8)
        @height = @config.height || (@canvas.height / 30)

        @x = @canvas.width / 2
        @y = @canvas.height - (@height / 2)

        @score = 0
        @lives = 3

    update: (leftPressed, rightPressed) ->
        if (@config.debug)
            console.log "Paddle.update() called"

        # basic movement logic
        if (leftPressed)
            @x -= @move_amount
        else if (rightPressed)
            @x += @move_amount

        # left/right wall boundaries
        if (@x + (@width / 2) > @canvas.width)
            @x = @canvas.width - (@width / 2)
        else if (@x - (@width / 2) < 0)
            @x = 0 + (@width / 2)

    draw: ->
        if (@config.debug)
            console.log "Paddle.draw() called"

        @context.fillStyle = "rgba(128,128,128,.8)"
        @context.fillRect(@x - (@width/2), @y - (@height/2), @width, @height)

class Ball
    constructor: (@config) ->
        if (@config.debug)
            console.log "initializing Ball"

        @context = @config.context
        @canvas = @config.canvas

        @radius = @config.radius || 5

        @max_speed = @config.max_speed || 8
        @max_bounce_angle = @config.max_bounce_angle || (5 * Math.PI/12)

        # start in the middle of the canvas
        # this should be the center of the object? depends on how it is drawn..
        @x = @canvas.width / 2
        @y = @canvas.height / 2

        @width = 2 * @radius
        @height = 2 * @radius

        # choose between either 1 (original physics) or 2 (like wall ball)
        @use_physics = @config.use_physics || 1

        # start off by dropping down
        #bleh = Math.round(Math.random()) ? 1 : - 1
        #@dx = 5 * bleh
        #@dy = 10 * bleh

        #if (@config.bounce_in_place || !@hasOwnProperty("dx"))
        @dx = 0
        @dy = @max_speed

        @was_bad = false
        @is_dead = false

    update: (paddle, bricks) ->
        if (@config.debug)
            console.log "Ball.update() called"

        # check speed limits
        if (@dx > @max_speed)
            @dx = @max_speed
        else if (@dx < 0 && @dx < -@max_speed)
            @dx = -@max_speed
        if (@dy > @max_speed)
            @dy = @max_speed
        else if (@dy < 0 && @dy < -@max_speed)
            @dy = -@max_speed

        @x += @dx
        @y += @dy

        # is the ball in a bad position?
        is_bad = false

        # check left/right boundaries
        if (@x >= @canvas.width || @x <= 0)
            is_bad = true
            @x -= 2 * @dx
            @dx = -@dx

        # check top/bottom boundaries
        if (@y <= 0)
            is_bad = true
            @y -= 2 * @dy
            @dy = -@dy

        if (@y >= @canvas.height)
            @is_dead = true
            return true

        # This is for keeping track of whether the ball was out of bounds last
        # iteration. This helps the game know to reset the ball position.
        # Otherwise the player might be left with a ball beyond the borders.
        # There should be no two consecutive frames of the game where the ball
        # is anywhere beyond the edge of the screen.
        if (is_bad && @was_bad)
            @x = @canvas.width / 2
            @y = @canvas.height / 2
            @dx = @max_speed # / 4
            @dy = @max_speed # / 4
            @was_bad = false
            @is_bad = false
        @was_bad = is_bad

        # check against paddle
        overlap = (ax, aw, bx, bw) ->
            return ! ((ax + aw) <= bx || ax >= (bx + bw))

        overlap2d = (ax, ay, aw, ah, bx, b_y, bw, bh) ->
            return overlap(ax, aw, bx, bw) && overlap(ay, ah, b_y, bh)

        overlap = overlap2d(@x, @y, @radius, @radius, paddle.x - (paddle.width / 2), paddle.y - (paddle.height / 2), paddle.width, paddle.height)
        if (overlap)
            if (@use_physics == 1)
                @y = 2 * paddle.y - (@y + @radius) - @height
                @dy = -@dy

                @dx = ((@x + (@radius * 0.5)) - (paddle.x + (paddle.width / 2))) * 4 / paddle.width
                if (@x > paddle.x)
                    @dx = -@dx
            else if (@use_physics == 2)
                relative_intersect_x = (paddle.x + (paddle.width / 2)) - @x
                normalized_relative_intersection_x = relative_intersect_x / (paddle.width / 2)
                bounce_angle = normalized_relative_intersection_x * @max_bounce_angle
                @dx = Math.cos(bounce_angle) * @max_speed
                @dy = -1 * Math.sin(bounce_angle) * @max_speed

        for brick in bricks
            if (!brick.dead)
                sx = brick.x
                left = sx - (brick.width / 2)
                right = sx + (brick.width / 2)
                horizontal = left <= @x <= right

                sy = brick.y
                top = sy - (brick.height / 2)
                bottom = sy + (brick.height / 2)
                vertical = top <= @y <= bottom

                if (horizontal && vertical)
                    console.log "hit a brick"
                    brick.dead = true

                    # reverse ball (bounce)
                    @dy = -@dy

                    b_y = Math.floor((@y + @radius * 0.5 - (brick.y - (brick.height / 2))) - brick.height)

                    if (b_y == 0)
                        if (@dy < 0)
                            @dy = -1 * @max_speed
                        else
                            @dy = @max_speed

                    paddle.score += 100
                    Gameprez.score("player", paddle.score)

    draw: ->
        if (@config.debug)
            console.log "Ball.draw() called"

        @context.fillStyle = "rgba(255, 255, 255, 1)"
        @context.beginPath()
        @context.arc(@x, @y, @radius, 0, 2 * Math.PI, false)
        @context.closePath()
        @context.fill()

class Brick
    constructor: (@config) ->
        if (@config.debug)
            console.log "initializing Brick"

        @context = @config.context
        @canvas = @config.canvas

        @width = @config.width
        @height = @config.height

        @color = @config.color

        @x = @config.x
        @y = @config.y

        @dead = false

    update: ->
        if (!@dead)
            true

    draw: ->
        if (!@dead)
            if (@config.debug)
                console.log "Brick.draw() called"

            @context.fillStyle = @color
            @context.fillRect(@x - (@width/2), @y - (@height/2), @width, @height)

class Game
    constructor: (@config) ->
        console.log "initializing Game"
        @canvas = null

        @bricks = []
        @ball = null
        @paddle = null

        @spacePressed = @leftPressed = @upPressed = @rightPressed = @downPressed = @zPressed = @aPressed = null

    main: ->
        console.log "starting a new game (in Game.main)"
        @create_canvas()

        # replays shouldn't be given access to the keyboard or mouse
        if (!Gameprez.gameIsReplay)
            # setup keyboard shortcuts
            @add_key_observers()

            # define how mouse movement should be handled
            moveMouse = (event) =>
                if (!event)
                    event = window.event
                    x = event.event.offsetX
                    y = event.event.offsetY
                else
                    x = event.pageX
                    y = event.pageY

                # basically just move the paddle
                @paddle.x = x 

            # bind the mouse handler to the document
            document.onmousemove = moveMouse

        Gameprez.updateMouse = (x, y) =>
            @paddle.x = x

        @start_new_game()

    start_new_game: ->
        console.log "start_new_game called"

        delete @ball
        delete @paddle
        delete @bricks

        Gameprez.start()
        Gameprez.gameData = {}
        Gameprez.gameData.pause = false

        @spawn_bricks()
        @spawn_ball()

        config =
            context: @context
            canvas: @canvas
            debug: @config.debug

        @paddle = new Paddle(config)

        # begin
        @update()

    spawn_bricks: ->
        console.log "spawn_bricks called"

        @bricks = []

        brick_start_y = 40
        brick_width = 20
        brick_height = 20
        brick_rows = 5
        brick_columns = Math.round(@canvas.width / brick_width)

        brick_colors = [
            "hsl(  0, 100%, 50%)",
            "hsl( 60, 100%, 50%)",
            "hsl(120, 100%, 50%)",
            "hsl(180, 100%, 50%)",
            "hsl(240, 100%, 50%)",
            "hsl(300, 100%, 50%)"
        ]

        for y in [0..brick_rows]
            for x in [0..brick_columns]
                xpos = x * brick_width
                ypos = y * brick_height + brick_start_y

                config =
                    x: xpos
                    y: ypos
                    width: brick_width
                    height: brick_height
                    color: brick_colors[y]
                    context: @context
                    canvas: @canvas

                brick = new Brick(config)
                @bricks.push(brick)

    spawn_ball: ->
        console.log("Game.spawn_ball() called")

        config =
            context: @context
            canvas: @canvas
            debug: @config.debug
            radius: 5
            max_speed: 8
            dx: 0
            dy: 0

        @ball = new Ball(config)

    # run when the game is quit to clean up everything
    reset: ->
        console.log "consider throwing away the old Game object"
        @terminate_run_loop = true
        @clear_screen()

    update: ->
        callback = (=> @update()) # or using underscore.. callback = _.bind(@update, @)

        if (@config.debug)
            console.log "Game.update() called"

        if (@paddle.lives == 0)
            Gameprez.gameData.pause = true

            @context.fillStyle = "rgba(255, 255, 255, 1)"
            @context.font = "bold 72px sans-serif"
            @context.fillText("FAILURE", @canvas.width/2 - 125, @canvas.height/2 + 50)
            @context.font = "bold 24px sans-serif"
            @context.fillText("Press 'z' to play again.", @canvas.width/2 - 115, @canvas.height/2 + 100)

            if (@zPressed)
                console.log "zPressed"
                @start_new_game()
                return

            # make looping happen
            window.setTimeout(callback, 1000/30)
            return

        @paddle.update(@leftPressed, @rightPressed)

        # and now the ball...
        @ball.update(@paddle, @bricks)

        if (@ball.is_dead)
            @paddle.lives -= 1
            @ball.is_dead = false
            if (@paddle.lives > 0)
                Gameprez.score("computer", (@paddle.config.lives || 3) - @paddle.lives)
                @spawn_ball()

        # draw all the things
        @draw()

        # make looping happen
        window.setTimeout(callback, 1000/30)

    draw: ->
        if (@config.debug)
            console.log "Game.draw() called"

        # clear the canvas for this frame
        @clear_screen()

        # draw the background
        @context.fillStyle = "rgba(0, 0, 0,1)"
        @context.fillRect(0, 0, @canvas.width, @canvas.height)

        living_bricks = 0

        # and now the bricks..
        for brick in @bricks
            if (!brick.dead)
                living_bricks += 1
                brick.draw()

        if (living_bricks == 0)
            @spawn_bricks()

        # and now the ball...
        @ball.draw()

        @paddle.draw()

        # draw information?
        @context.fillStyle = "rgba(255, 0, 0, 1)"
        @context.font = "bold 12px sans-serif"
        @context.fillText("score: " + @paddle.score, 5, 15)
        @context.fillText("lives: " + @paddle.lives, 100, 15)

    create_canvas: ->
        @canvas = document.getElementsByTagName("canvas")[0]
        @context = @canvas.getContext("2d")

    clear_screen: ->
        @context.fillStyle = "rgba(0, 0, 0, 1)"
        @context.clearRect(0, 0, @canvas.width, @canvas.height)

    add_key_observers: ->
        document.addEventListener("keydown", (e) =>
            switch e.keyCode
                when 32 then @spacePressed = true
                when 37 then @leftPressed = true
                when 38 then @upPressed = true
                when 39 then @rightPressed = true
                when 40 then @downPressed = true
                when 90 then @zPressed = true
                when 65 then @aPressed = true
        , false)

        document.addEventListener("keyup", (e) =>
            switch e.keyCode
                when 27 then @reset()
                when 32 then @spacePressed = false
                when 37 then @leftPressed = false
                when 38 then @upPressed = false
                when 39 then @rightPressed = false
                when 40 then @downPressed = false
                when 90 then @zPressed = false
                when 65 then @aPressed = false
        , false)

config =
    debug: false

game = new Game(config)
game.main()
