
--screaming_bird's bird_and_pipes.vhd file

--CREDITS AND REFRENCES:
--based on lab 6 (pong) bat_n_ball.vhd
--and flappy atilla project - https://github.com/BriannaPGarland/FlappyAttila/blob/main/ProjectFiles/bird_n_buildings.vhd
--and 2019 flappy bird project - https://sites.google.com/stevens.edu/cpe487website/project

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY bird_and_pipes IS
    PORT (
        v_sync : IN STD_LOGIC;
        pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
      
      --ignore, we are focusing on BIRD (aka only the ball!) changed from bat_x 
      --  bird_x : IN STD_LOGIC_VECTOR (10 DOWNTO 0); -- current bat_x position
       
        serve : IN STD_LOGIC; -- initiates serve
        hits : out std_logic_vector(15 downto 0); --added hit counter
        
        audio_peak : in std_logic; --our method of controlling the bird
        --audio trigger = 1 when loud enough audio is detected!!

        --ports for colors. our bird will be blue, and pipes will be green!
        red : OUT STD_LOGIC;
        green : OUT STD_LOGIC;
        blue : OUT STD_LOGIC
       
    );
END bird_and_pipes;

ARCHITECTURE Behavioral OF bird_and_pipes IS
    --bird size in pixels:
    CONSTANT bsize : INTEGER := 8; -- ball radius in pixels
    
    CONSTANT bird_speed : STD_LOGIC_VECTOR (10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR (6, 11);
    --boundary size constant
    CONSTANT bound_h : INTEGER := 65; -- thickness of the bound
    
    --signals...
    signal gapsize : integer := 120;
    signal score : integer := 0;
    signal gap_speed : std_logic_vector(9 downto 0) := conv_std_logic_vector(5, 10);
    SIGNAL x : integer :=320;
    SIGNAL flag : integer :=0; -- variable to determine what type of game is happening 


    signal bound_on : std_logic;
    signal bird_on : std_logic;
    signal building_on : std_logic;
    signal background_on : std_logic;
    signal game_on : std_logic := '0';
    
    --gap_pos = vertical center of gap - 10 bits
    signal gap_pos : std_logic_vector(9 downto 0) :=  conv_std_logic_vector(640, 10);
    
    --bound_y used as the pipe's x position
    signal bound_y : std_logic_vector(9 downto 0) := conv_std_logic_vector(640, 10);
    signal bound_y_motion : STD_LOGIC_VECTOR(9 DOWNTO 0) := gap_speed;

    --signals for the bird, from lab 6 pong:
    -- current ball position - intitialized to center of screen
    SIGNAL bird_x : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(400, 11);
    SIGNAL bird_y : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(300, 11);
    SIGNAL bird_x_motion, bird_y_motion : STD_LOGIC_VECTOR(10 DOWNTO 0) := bird_speed;
  
    --integer helpers for bird physics and movement
    signal bird_y_int : integer := 300;
    signal bird_y_vel_int : integer := 0;
    constant jump_strength : integer := -40; --upwards jump in pixels
    constant gravity : integer := 4; --fall speed increment
  
BEGIN

    --assign hits output to reflect the score
    hits <= conv_std_logic_vector(score, 16);
   -- color setup for blue bird and green pipes on a white background
    red <= '0' when building_on = '0' and bound_on = '0' else '1';
    green <= building_on or bound_on;
    blue <= bird_on and background_on;
    
    --drawing the BIRD, referencing balldraw from lab 6 pong
    --because... our bird will be a ball... heheheh..... hehe.. he...
    birddraw : process (bird_x, bird_y, pixel_row, pixel_col) is
        variable vx, vy : std_logic_vector(10 downto 0);
        begin
            if pixel_col <= bird_x then
                vx := bird_x - pixel_col;
            else
                vx := pixel_col - bird_x;
            end if;
            if pixel_row <= bird_y then
                vy := bird_y - pixel_row;
            else
                vy := pixel_row - bird_y;
            end if;
            if ((vx * vx) + (vy * vy)) < (bsize * bsize) then
                bird_on <= game_on;
            else
                bird_on <= '0';
            end if;
     end process;	
     
     --drawing the background now
     --process code segment from flappy atilla's bird_n_buildings:
     backgrounddraw: PROCESS (pixel_row, pixel_col) IS
		VARIABLE vx, vy : STD_LOGIC_VECTOR (9 DOWNTO 0);
	    BEGIN
		IF (conv_integer(unsigned(pixel_row)) >= 0) AND conv_integer(unsigned(pixel_row))<= 800 AND conv_integer(unsigned(pixel_col)) >= 0 AND conv_integer(unsigned(pixel_col))<= 800 THEN
			background_on <= '1';
		ELSE
			background_on <= '0';
		END IF;
	 END PROCESS;
     
     --drawing the gapset gap_on 
     --process code segment from flappy atilla's bird_n_buildings:
    gapdraw : PROCESS (bound_y, gap_pos, pixel_row, pixel_col) IS
		--VARIABLE vx, vy : STD_LOGIC_VECTOR (9 DOWNTO 0);
        BEGIN	
            IF (pixel_row >= gap_pos - gapsize/2) AND  --check if inside vertical opening
               (pixel_row <= gap_pos + gapsize/2) AND
               (pixel_col >= bound_y - bound_h) AND
               (pixel_col <= bound_y + bound_h) THEN
                    bound_on <= '1';
            ELSE
                bound_on <= '0';
		END IF;
	END PROCESS;
	
	--drawing the pipes above and below the gap (top and bottom of screen)
    --process code segment from flappy atilla's bird_n_buildings:
    buildingdraw: PROCESS (bound_y, gap_pos, pixel_row, pixel_col) IS
		--VARIABLE vx, vy : STD_LOGIC_VECTOR (9 DOWNTO 0);
        BEGIN
            IF (pixel_col >= bound_y - bound_h) AND --pipe hori range
               (pixel_col <= bound_y + bound_h) THEN
                IF (pixel_row < gap_pos-gapsize/2) then --pixel above gap?
                    building_on <= '1';
                
                ELSIF (pixel_row > gap_pos + gapsize/2) then --pixel below gap?
                    building_on <= '1';
                ELSE
                    building_on <= '0';    
                END IF;
            ELSE
                building_on <= '0';
            END IF;
	END PROCESS;
	
	--bird physics.... yeah...
	birdphysics : process
	begin
	   wait until rising_edge(v_sync);
	   if game_on = '1' then
	       if audio_peak = '1' then
	           bird_y_vel_int <= jump_strength;
	       end if;
	       bird_y_vel_int <= bird_y_vel_int + gravity;
	       bird_y_int <= bird_y_int + bird_y_vel_int;
	       
	       if bird_y_int < 10 THEN
                bird_y_int <= 10;
            elsif bird_y_int > 470 THEN
                bird_y_int <= 470;
            end if;
            
        else 
          bird_y_int <= 300;
          bird_y_vel_int <= 0;
        end if;
        bird_y <= conv_std_logic_vector(bird_y_int, 11);
     end process;
	       
	       
	
	--game logic!!!
	
	--process to move the gap once every frame
	--process code segment from flappy atilla's bird_n_buildings:
	--maybe? need to modify in order to incorporate that audio control.
	--this section needs major repairs. 
	mgap : PROCESS
		--VARIABLE temp : STD_LOGIC_VECTOR (10 DOWNTO 0);
		variable next_y : integer;
		variable next_x : integer;
		variable bird_r : integer := bsize;
		variable bird_left, bird_right : integer;
		variable gap_top, gap_bottom : integer;
	BEGIN
		WAIT UNTIL rising_edge(v_sync);
		
		--This is checking if this is the first serve of the game because it resets everything 
		--PART 1: game reset/serve function
		IF serve = '1' AND game_on = '0' AND audio_peak = '1' THEN -- test for new serve
            game_on <= '1';
		    score<=0;
		    gapsize<=120;
		    --pipes start on the right
		    next_x := 640;
		    bound_y <= conv_std_logic_vector(next_x, 10);
		    --vertical gap reset
            gap_pos <= conv_std_logic_vector(320, 10); --vertical gap center
		    --reset pipe hori speed
            gap_speed <= conv_std_logic_vector(5, 10);
            bound_y_motion <= gap_speed;
        
        --PART 2: moving pipe across the screen (pipe moves left)
            next_x := conv_integer(unsigned(bound_y)) - conv_integer(unsigned(bound_y_motion));
            --respawn the pipe at right edge once it moves offscreen
		    if next_x < 0 then
                score <= score + 1;	
                --randomized vertical gap formula from bird_and_buildings	   
                x <=((123*(score**2)) mod 560)+40;
                IF x<40 THEN
                    x <=40;
                ELSIF x>600 THEN
                        x <=600;
		        END IF;
		   	 gap_pos <= CONV_STD_LOGIC_VECTOR(x, 10);
		   	 next_x := 640; --reset pipe position to right side of screen
		END IF;
        --updated pipe x position
        bound_y <= CONV_STD_LOGIC_VECTOR(next_x, 10);

		--PART 3: collision detection!!!!!	
		-- This checks if you landed within the gap and allows you to add to the score until you win @ 15 points and the score resets
		
		bird_left := conv_integer(unsigned(bird_x)) - bird_r;
		bird_right := conv_integer(unsigned(bird_x)) + bird_r;
		
		--calculating gap vertical region...
		gap_top := conv_integer(unsigned(gap_pos)) - gapsize/2;
		gap_bottom := conv_integer(unsigned(gap_pos)) + gapsize/2;
		
		--pipe horizontal region is a 2*bound_h wide column
		--pipe vertical region is entire screen save for btwn gap_top/bottom
	       
	      --check if bird is inside horizontal region
		  if bird_right >= next_x - bound_h and
		     bird_left <= next_x + bound_h then
		      --check if da bird is inside gap vertically
		      if (conv_integer(unsigned(bird_y)) < gap_top) or 
		          (conv_integer(unsigned(bird_y)) > gap_bottom) then
		          --oooppppss u died!! bird collison = game ovrrr
		          game_on <= '0';
		          score <= 0;
		          gapsize <= 120;
		          bound_y_motion <= gap_speed;
		     end if;
		  end if;
		 end if;
	end process;

end behavioral;

