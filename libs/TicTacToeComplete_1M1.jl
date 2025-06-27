# Complete Tic-Tac-Toe Game Implementation

mutable struct TicTacToeGame
    board::Matrix{Char}
    current_player::Char
    game_over::Bool
    winner::Union{Char, Nothing}
    moves_count::Int
end

@api function create_game()
    return TicTacToeGame(fill(' ', 3, 3), 'X', false, nothing, 0)
end

@api function is_valid_move(game::TicTacToeGame, row::Int, col::Int)
    return 1 <= row <= 3 && 1 <= col <= 3 && game.board[row, col] == ' ' && !game.game_over
end

@api function make_move!(game::TicTacToeGame, row::Int, col::Int)
    if !is_valid_move(game, row, col)
        return false
    end
    
    game.board[row, col] = game.current_player
    game.moves_count += 1
    
    if check_winner(game)
        game.winner = game.current_player
        game.game_over = true
    elseif game.moves_count >= 9
        game.game_over = true
        game.winner = nothing  # tie
    else
        game.current_player = game.current_player == 'X' ? 'O' : 'X'
    end
    
    return true
end

@api function check_winner(game::TicTacToeGame)
    board = game.board
    player = game.current_player
    
    # Check rows
    for i in 1:3
        if all(board[i, :] .== player)
            return true
        end
    end
    
    # Check columns
    for j in 1:3
        if all(board[:, j] .== player)
            return true
        end
    end
    
    # Check diagonals
    if all([board[i, i] for i in 1:3] .== player)
        return true
    end
    if all([board[i, 4-i] for i in 1:3] .== player)
        return true
    end
    
    return false
end

@api function reset_game!(game::TicTacToeGame)
    game.board = fill(' ', 3, 3)
    game.current_player = 'X'
    game.game_over = false
    game.winner = nothing
    game.moves_count = 0
end

@api function render_game_html(game::TicTacToeGame)
    status_message = if game.game_over
        if game.winner !== nothing
            "Player $(game.winner) wins!"
        else
            "It's a tie!"
        end
    else
        "Current Player: $(game.current_player)"
    end
    
    html = """
    <div style="font-family: Arial, sans-serif; text-align: center; max-width: 400px; margin: 0 auto;">
        <h1 style="color: #333;">Tic-Tac-Toe</h1>
        <div style="display: grid; grid-template-columns: repeat(3, 80px); grid-gap: 5px; justify-content: center; margin: 20px auto;">
    """
    
    for i in 1:3
        for j in 1:3
            cell_content = game.board[i, j] == ' ' ? "&nbsp;" : string(game.board[i, j])
            cell_style = """
                width: 80px; height: 80px; border: 3px solid #333; 
                display: flex; align-items: center; justify-content: center; 
                font-size: 24px; font-weight: bold; cursor: pointer; 
                background-color: #f9f9f9; transition: background-color 0.2s;
            """
            
            if game.board[i, j] == ' ' && !game.game_over
                cell_style *= " background-color: #e8f4f8;"
            end
            
            html *= """
            <div onclick="makeMove($i, $j)" style="$cell_style">
                $cell_content
            </div>
            """
        end
    end
    
    html *= """
        </div>
        <h2 style="color: $(game.game_over ? "#d32f2f" : "#1976d2");">$status_message</h2>
        <button onclick="resetGame()" style="
            padding: 12px 24px; font-size: 16px; background-color: #4caf50; 
            color: white; border: none; border-radius: 5px; cursor: pointer;
            margin-top: 10px;
        ">New Game</button>
    </div>
    
    <script>
        function makeMove(row, col) {
            console.log('Move:', row, col);
        }
        
        function resetGame() {
            location.reload();
        }
    </script>
    """
    
    return html
end

@api function render_interactive_game_html(game::TicTacToeGame)
    status_message = if game.game_over
        if game.winner !== nothing
            "Player $(game.winner) wins!"
        else
            "It's a tie!"
        end
    else
        "Current Player: $(game.current_player)"
    end
    
    html = """
    <div style="font-family: Arial, sans-serif; text-align: center; max-width: 400px; margin: 0 auto;">
        <h1 style="color: #333;">Interactive Tic-Tac-Toe</h1>
        <div id="game-board" style="display: grid; grid-template-columns: repeat(3, 80px); grid-gap: 5px; justify-content: center; margin: 20px auto;">
    """
    
    for i in 1:3
        for j in 1:3
            cell_content = game.board[i, j] == ' ' ? "&nbsp;" : string(game.board[i, j])
            cell_style = """
                width: 80px; height: 80px; border: 3px solid #333; 
                display: flex; align-items: center; justify-content: center; 
                font-size: 24px; font-weight: bold; cursor: pointer; 
                background-color: #f9f9f9; transition: background-color 0.2s;
            """
            
            if game.board[i, j] == ' ' && !game.game_over
                cell_style *= " background-color: #e8f4f8;"
                onclick = "makeMove($i, $j)"
            else
                onclick = ""
            end
            
            html *= """
            <div onclick="$onclick" style="$cell_style">
                $cell_content
            </div>
            """
        end
    end
    
    html *= """
        </div>
        <h2 id="status" style="color: $(game.game_over ? "#d32f2f" : "#1976d2");">$status_message</h2>
        <button onclick="resetGame()" style="
            padding: 12px 24px; font-size: 16px; background-color: #4caf50; 
            color: white; border: none; border-radius: 5px; cursor: pointer;
            margin-top: 10px;
        ">New Game</button>
        <div style="margin-top: 20px; font-size: 14px; color: #666;">
            <p>Click cells to play or type commands like:</p>
            <p>'make move at row 1, column 2' or 'reset the game'</p>
        </div>
    </div>
    
    <script>
        let gameState = {
            currentPlayer: '$(game.current_player)',
            gameOver: $(game.game_over),
            winner: $(game.winner === nothing ? "null" : "'$(game.winner)'")
        };
        
        function makeMove(row, col) {
            if (gameState.gameOver) return;
            
            let moveCommand = 'make move at row ' + row + ', column ' + col;
            console.log('Sending move:', moveCommand);
        }
        
        function resetGame() {
            let resetCommand = 'reset the game';
            console.log('Sending reset:', resetCommand);
        }
    </script>
    """
    
    return html
end

@api function process_move(row::Int, col::Int)
    game = memory[:game]
    
    if make_move!(game, row, col)
        html = render_interactive_game_html(game)
        
        if game.game_over
            if game.winner !== nothing
                audio_msg = "Player $(game.winner) wins! Game over."
            else
                audio_msg = "It's a tie! Game over."
            end
        else
            audio_msg = "Move made. Current player is $(game.current_player)."
        end
        
        put!(outputs[:Browser], html, audio_msg)
        return true
    else
        html = render_interactive_game_html(game)
        put!(outputs[:Browser], html, "Invalid move! Please try again.")
        return false
    end
end

@api function process_reset()
    game = memory[:game]
    reset_game!(game)
    html = render_interactive_game_html(game)
    put!(outputs[:Browser], html, "Game reset! Player X starts.")
end
