--create the bird, pipes, and game logic functionalities
--referenced from flappy atilla and lab 6's bat_n_ball

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity bird_and_pipes is
    port(
        v_sync    : IN  STD_LOGIC;
        pixel_row : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
        pixel_col : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
        serve : IN  STD_LOGIC; -- start/reset
        flap  : IN  STD_LOGIC; -- 1-frame pulse
        hits  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        red   : OUT STD_LOGIC;
        green : OUT STD_LOGIC;
        blue  : OUT STD_LOGIC
    );
end bird_and_pipes;

architecture Behavioral of bird_and_pipes is
    --constants for drawing game items and setting restrictions
    --screen constants:
    constant screen_w : integer := 800;
    constant screen_h : integer := 600;
    
    --creating the bird (a ball):
    constant bsize : integer := 8;
    constant bird_x : integer := 200; --bird's x position
    
    --constants for the bird physics (only moves in y direction):
    constant gravity : integer := 1; --pull bird down when not jumping up
    constant jump_vel : integer := -10; --jump velocity
    constant max_fall_vel : integer := 12;--the max velocity the bird can fall
    
    --constants for the pipes (basic rectangles that move across the screen):
    constant pipe_w : integer := 60;
    constant pipe_speed : integer := 6;
    constant gap_h : integer := 150; --gap logic inspired & ref from flappy atilla
    
    --signals for the game:
    signal bird_on : std_logic := '0'; --turns on when game starts (btn0 is pushed)
    signal pipe_on : std_logic := '0';
    signal game_on : std_logic := '0'; -- states if game is on or not
    
    --bird signals:
    signal bird_y : integer := 300; --bird's vertical center on the screen
    signal bird_vy : integer := 0; --bird's vertical velocity; helps to separate physics from drawing stats
    
    --pipe & gap signals:
    signal pipe_x : integer := 760;
    signal gap_y : integer := 220;
    
    --score signal:
    signal score : std_logic_vector(15 downto 0) := (others => '0');
    signal scored : std_logic := '0'; --prevents double scoring!!!!

    --made up signal so that the randomization works
    signal lfsr : std_logic_vector(9 downto 0) := "1010010110"; --non zero seed for linear feedback shift register for pseudo random number;  ref: https://surf-vhdl.com/how-to-implement-an-lfsr-in-vhdl/
    --signal stores current state of lsfr and shifts bits + combines specific bits to make pseudoramdom sequences
begin
    --link hits to the score
    hits <= score;
    
    --logic for making the bg white, pipe green. and the bird blue
    --not sure why the bat_n_ball logic didnt work here so its been rewritten
    --more complicated but it worked ...
    process(bird_on, pipe_on)
    begin
        if pipe_on = '1' then
            red <= '0'; green <= '1'; blue <= '0';
        elsif bird_on = '1' then
             red <= '0'; green <= '0'; blue <= '1';
        else
            red <= '1'; green <= '1'; blue <= '1';
        end if;
    end process;
    
    --bird draw (circle), referencing ball_draw:
    --in ball_draw, the ball is always on
    --in bird_draw, the bird is on when game_on = 1 
    bird_draw : process(bird_y, game_on, pixel_row, pixel_col)
        variable vx, vy : integer; --temp variables to convert values so the equations work
        variable r, c : integer; --variables to conv current pixel being drawn from std_logic_vector into INTEGERS to do math; c - x coord, r = y coord
    begin
        r := conv_integer(pixel_row);
        c := conv_integer(pixel_col);
        --the following if statements convert unsigned pixel coordibates into absolute distance
        --so vx = hori distance from bird center
        -- vy = vertical distance from bird center
        --and avoids negative numbers
        if c <= bird_x then vx := bird_x - c; 
        else vx := c - bird_x; 
        end if;
        
        if r <= bird_y then vy := bird_y - r; 
        else vy := r - bird_y; 
        end if;
        
        --from bat_n_ball! here is the CIRCLE EQUATION
        if (game_on = '1') and ((vx*vx + vy*vy) < (bsize*bsize)) then
            bird_on <= '1';
        else
            bird_on <= '0';
        end if;
    end process;
    
    --process to draw the pipes, two rectangles w a gap in btwn
    pipe_draw: process(pipe_x, gap_y, game_on, pixel_row, pixel_col)
        variable r, c : integer;
    begin
        r := conv_integer(pixel_row);
        c := conv_integer(pixel_col);
        
        if (game_on = '1') and 
        (c >= pipe_x) and (c < pipe_x + pipe_w) and --hori pipe bounds (pixel is within pipe width)
        ((r < gap_y) or (r >= gap_y + gap_h)) then --vertical exclusion zone = GAP (draw pipe above or below gap)
            pipe_on <= '1';
        else
            pipe_on <= '0';
        end if;
    end process;
    
    --process to be update once per frame
    game_tick : process
        variable new_gap : integer;
        variable bird_left, bird_right : integer;
        variable bird_top, bird_bot : integer;
        variable pipe_left, pipe_right : integer;
        variable gap_top, gap_bot : integer;
    begin
        wait until rising_edge(v_sync); --vsync happens once per frame (60hz) so we update game on the vertical sync to have consistent physics independent of clock speed
        if (serve = '1') and (game_on = '0') then
            game_on <= '1';
            bird_y  <= 300;
            bird_vy <= 0;
            pipe_x  <= 760;
            gap_y   <= 220;
            score   <= (others => '0');
            scored  <= '0';
            lfsr    <= "1010010110";
            
        elsif (game_on = '1') then
            --determine if the bird goes up (flap) or down (gravity)
            if flap = '1' then
                bird_vy <= jump_vel; --bird JUMPS up
            else
                if bird_vy < max_fall_vel then --max_fall_vel limits the fall speed
                    bird_vy <= bird_vy + gravity; --gravity accelerated downwards over time
                end if;
            end if;
            bird_y <= bird_y + bird_vy;
            
            --top or bottom losing logic
            if (bird_y - bsize < 0) or (bird_y + bsize >= screen_h) then
                game_on <= '0';
            end if;
            
            --moving the pipe
            pipe_x <= pipe_x - pipe_speed;
            
            --respawn the pipe
            if (pipe_x + pipe_w < 0) then --if pipe is fully offscreen, RESPAWN IT
                pipe_x <= screen_w; --this math keeps the gap within the screen
                lfsr <= lfsr(8 DOWNTO 0) & (lfsr(9) XOR lfsr(6));
                new_gap := 40 + (CONV_INTEGER(lfsr) MOD (screen_h - gap_h - 80));
                gap_y <= new_gap;
                scored <= '0';
            end if;
            
            --scoring logic
            if (scored = '0') and (pipe_x + pipe_w < bird_x - bsize) then
                score  <= score + 1;
                scored <= '1';
            end if;
            
            --collision logic, essentially making a bounding box
            --rectangle math is simpler
            --implemented using axis aligned bounding boxes
            -- if bird overlaps pipe horizontally and is not within gap vertically, the game ends
            --the bird is drawn as a circle, but we approx it within a box for collisions
            bird_left := bird_x - bsize; --bird_x and bird_y are the center of the bird; bsize is the radius
            bird_right := bird_x + bsize; --the bird occupies x from: (bird_x - bsize) to (bird_x + bsize) and y from: (bird_y - bsize) to (bird_y + bsize)
            bird_top := bird_y - bsize;
            bird_bot := bird_y + bsize;
            pipe_left := pipe_x;   --defining the pipe rectangle;
            pipe_right := pipe_x + pipe_w - 1; 
            gap_top := gap_y; --defining the gap (safe vertical region)
            gap_bot := gap_y + gap_h - 1;
            --x axis horizontal overlap check)
            if (bird_right >= pipe_left) and (bird_left <= pipe_right) then
                if (bird_top < gap_top) or (bird_bot > gap_bot) then --then, a more specific y axis vertical collision check
                    game_on <= '0';
                end if;
            end if;
        end if;
    end process;
end Behavioral;
            
            
       
