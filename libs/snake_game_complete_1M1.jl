using Test

@api function create_snake_game_state()
    Dict{Symbol, Any}(
        :snake => [(10, 10), (10, 11), (10, 12)],
        :direction => (0, -1),
        :food => (5, 5),
        :score => 0,
        :game_over => false,
        :board_width => 20,
        :board_height => 20
    )
end

@api function move_snake(game_state)
    if game_state[:game_over]
        return game_state
    end
    
    head = game_state[:snake][1]
    new_head = (head[1] + game_state[:direction][1], head[2] + game_state[:direction][2])
    
    # Check wall collision
    if new_head[1] < 1 || new_head[1] > game_state[:board_width] || 
       new_head[2] < 1 || new_head[2] > game_state[:board_height]
        game_state[:game_over] = true
        return game_state
    end
    
    # Check self collision
    if new_head in game_state[:snake]
        game_state[:game_over] = true
        return game_state
    end
    
    new_snake = [new_head, game_state[:snake]...]
    
    # Check food collision
    if new_head == game_state[:food]
        game_state[:score] += 1
        game_state[:food] = generate_food_position(new_snake, game_state[:board_width], game_state[:board_height])
    else
        new_snake = new_snake[1:end-1]
    end
    
    game_state[:snake] = new_snake
    return game_state
end

@api function generate_food_position(snake, width, height)
    while true
        pos = (rand(1:width), rand(1:height))
        if pos ∉ snake
            return pos
        end
    end
end

@api function render_snake_game_html(game_state)
    board_html = ""
    for y in 1:game_state[:board_height]
        for x in 1:game_state[:board_width]
            cell_class = "empty"
            if (x, y) in game_state[:snake]
                cell_class = (x, y) == game_state[:snake][1] ? "snake-head" : "snake-body"
            elseif (x, y) == game_state[:food]
                cell_class = "food"
            end
            board_html *= "<div class='cell $cell_class'></div>"
        end
    end
    
    return """
    <div style="text-align: center; font-family: Arial, sans-serif;">
        <h2>Snake Game</h2>
        <div>Score: $(game_state[:score]) | Status: $(game_state[:game_over] ? "Game Over!" : "Playing")</div>
        <div id="game-board" style="
            display: grid;
            grid-template-columns: repeat($(game_state[:board_width]), 20px);
            grid-gap: 1px;
            background: #333;
            padding: 10px;
            margin: 20px auto;
            width: fit-content;
            border: 2px solid #666;
        ">
            $board_html
        </div>
        <div style="margin: 20px;">
            <button onclick="restartGame()" style="
                padding: 10px 20px;
                font-size: 16px;
                background: #4CAF50;
                color: white;
                border: none;
                border-radius: 5px;
                cursor: pointer;
            ">$(game_state[:game_over] ? "Start New Game" : "Restart Game")</button>
        </div>
        <div style="margin-top: 20px;">
            <p><strong>Controls:</strong> Use arrow keys ↑ ↓ ← → to move</p>
        </div>
    </div>
    
    <style>
        .cell {
            width: 20px;
            height: 20px;
            background: #000;
        }
        .snake-head {
            background: #0f0 !important;
            border: 1px solid #fff;
        }
        .snake-body {
            background: #090 !important;
        }
        .food {
            background: #f00 !important;
            border-radius: 50%;
        }
    </style>
    
    <script>
        let gameRunning = !$(game_state[:game_over]);
        
        document.addEventListener('keydown', function(e) {
            if (!gameRunning && e.key !== 'r') return;
            
            let direction = null;
            switch(e.key) {
                case 'ArrowUp': 
                    direction = [0, -1]; 
                    e.preventDefault();
                    break;
                case 'ArrowDown': 
                    direction = [0, 1]; 
                    e.preventDefault();
                    break;
                case 'ArrowLeft': 
                    direction = [-1, 0]; 
                    e.preventDefault();
                    break;
                case 'ArrowRight': 
                    direction = [1, 0]; 
                    e.preventDefault();
                    break;
                case 'r':
                case 'R':
                    restartGame();
                    return;
            }
            
            if (direction && ws && ws.readyState === WebSocket.OPEN) {
                ws.send('julia>memory[:snake_direction] = (' + direction[0] + ', ' + direction[1] + '); nothing');
            }
        });
        
        function restartGame() {
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send('julia>memory[:snake_restart] = true; nothing');
                gameRunning = true;
            }
        }
        
        window.focus();
        document.body.focus();
    </script>
    """
end

@api function start_snake_game_loop()
    Threads.@spawn begin
        while true
            sleep(0.2)
            
            if !haskey(memory, :snake_game_state)
                sleep(1)
                continue
            end
            
            game_state = memory[:snake_game_state]
            
            if haskey(memory, :snake_restart) && memory[:snake_restart]
                memory[:snake_game_state] = create_snake_game_state()
                memory[:snake_restart] = false
                put!(outputs[:Browser], render_snake_game_html(memory[:snake_game_state]))
                continue
            end
            
            if haskey(memory, :snake_direction)
                new_dir = memory[:snake_direction]
                current_dir = game_state[:direction]
                if (new_dir[1] != -current_dir[1] || new_dir[2] != -current_dir[2])
                    game_state[:direction] = new_dir
                end
                delete!(memory, :snake_direction)
            end
            
            if game_state[:game_over]
                sleep(1)
                continue
            end
            
            memory[:snake_game_state] = move_snake(game_state)
            put!(outputs[:Browser], render_snake_game_html(memory[:snake_game_state]))
        end
    end
end
