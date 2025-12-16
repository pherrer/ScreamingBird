
--ACTUAL SUBMISSION
--referenced from: pong lab, flappy atilla, audio visual equalizer

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity flap_top is
    port (
        clk_in : IN STD_LOGIC;
        VGA_red   : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_green : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_blue  : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_hsync : OUT STD_LOGIC;
        VGA_vsync : OUT STD_LOGIC;
        btn0 : IN STD_LOGIC; -- serve,start,reset button
        btnl : IN STD_LOGIC;
      --match mic ports to xdc
        micClk   : OUT STD_LOGIC;
        micData  : IN  STD_LOGIC;
        micLRSel : OUT STD_LOGIC;
        SEG7_anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
        SEG7_seg   : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
    );
end flap_top;

architecture Behavioral of flap_top is
    signal pxl_clk : std_logic := '0';
    signal S_red, S_green, S_blue : std_logic;
    signal S_vsync : std_logic;
    signal S_pixel_row, S_pixel_col : std_logic_vector(10 downto 0);
    
    signal count: std_logic_vector(20 downto 0) := (others => '0');
    signal display : std_logic_vector(15 downto 0) := (others => '0');
    signal led_mpx : std_logic_vector(2 downto 0);
    
    --mic sigs
    signal pdm_done : std_logic;
    signal pdm_bits : std_logic_vector(15 downto 0);
    signal loud_clk : std_logic := '0';
    
    --flap pulse
    signal flap_req : std_logic := '0';
    signal loud_vs_prev : std_logic := '0';
    
    --components made for flappy_scream (used references)
    component PdmDes is --modified from audio visualizer & equalizer noise detector
        generic(
            C_NR_OF_BITS : integer := 16;
            C_SYS_CLK_FREQ_MHZ : integer := 100;
            C_PDM_FREQ_HZ : integer := 2000000
        );
        port(
            clk_i : IN std_logic;
            en_i  : IN std_logic;
    
            done_o : OUT std_logic;
            data_o : OUT std_logic_vector(15 DOWNTO 0);
    
            pdm_m_clk_o      : OUT std_logic;
            pdm_m_data_i     : IN  std_logic;
            pdm_lrsel_o      : OUT std_logic;
            pdm_clk_rising_o : OUT std_logic
        );
    end component;
    
    component bird_and_pipes is --modified from bat_n_ball
        port(
            v_sync    : IN  STD_LOGIC;
            pixel_row : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
            pixel_col : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
            serve : IN  STD_LOGIC;
            flap  : IN  STD_LOGIC;
            hits  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            red   : OUT STD_LOGIC;
            green : OUT STD_LOGIC;
            blue  : OUT STD_LOGIC
        );
    end component;
    
    --components from labs & refs:
    COMPONENT vga_sync IS
        PORT (
            pixel_clk : IN STD_LOGIC;
            red_in    : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
            green_in  : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
            blue_in   : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
            red_out   : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            green_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            blue_out  : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            hsync     : OUT STD_LOGIC;
            vsync     : OUT STD_LOGIC;
            pixel_row : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
            pixel_col : OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT clk_wiz_0 is
        PORT (
            clk_in1  : in std_logic;
            clk_out1 : out std_logic
        );
    END COMPONENT;
    
    COMPONENT leddec16 IS
        PORT (
            dig : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
            data : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
        );
    END COMPONENT; 

begin
    --instantiations for flappy_scream , used refs
    --mic
    mic0 : PdmDes
    generic map(
        C_NR_OF_BITS => 16,
        C_SYS_CLK_FREQ_MHZ => 100,
        C_PDM_FREQ_HZ => 2000000
    )
    port map(
        clk_i => clk_in,
        en_i  => '1',
        done_o => pdm_done,
        data_o => pdm_bits,
        pdm_m_clk_o      => micClk,
        pdm_m_data_i     => micData,
        pdm_lrsel_o      => micLRSel,
        pdm_clk_rising_o => OPEN
    );
    
    --loudness detector process
    -- mic gives u pdm audio; process coverts this into prm bits (1 = loud, 0 = not loud)
    process(clk_in)
        variable ones : integer;
        variable i : integer;
        constant thresh : integer := 1; --could be changed a lil... CHANGED FROM 12 => 1 
    begin
        if rising_edge(clk_in) then
            if pdm_done = '1' then --the pdmdes sample is valid
                ones := 0;
                for i in 0 to 15 loop --https://surf-vhdl.com/vhdl-for-loop-statement/
                    if pdm_bits(i) = '1' then --count how many bits are '1' (loud)
                        ones := ones + 1;     -- when then approx signal energy
                    end if;                   -- essentially is a hardware volume detector
                end loop;
                if ones > thresh then --thresh := 12 which means that more than 12 '1''s mean a signal is loud
                    loud_clk <= '1';  --convert the loud '1' analog data to digital
                else                  -- this is the scream detector
                    loud_clk <= '0'; --note: we do not use loud_clk directly to jump b/c it stays high if you keep yelling
                end if;              -- this would cause the bird to jump every clock and teleport offscreen, so we edge detect it
            end if;
        end if;
    end process;
    
    --flap_req one frame pulse process
    --we conv the pdm stream into binary loudness signal by counting no. of high bits in sample window
    --edge detecting the loudness signal w/ vga vertical sync prevents continuous jumping
    --this produces a single cycle flap pulse sync to the game frame rate
   --converts a loud sound to a SINGLE JUMP and limits jumping to once per video frame
    process(S_vsync)
    begin
        if rising_edge(S_vsync) then
            if (loud_clk = '1') AND (loud_vs_prev = '0') then
                flap_req <= '1';
            else
                flap_req <= '0';
            end if;
            loud_vs_prev <= loud_clk;
        end if;
    end process;
    
    --modded from pong's port maps and flappy atilla and stuff
    game0 : bird_and_pipes
        port map(
            v_sync    => S_vsync,
            pixel_row => S_pixel_row,
            pixel_col => S_pixel_col,
    
            serve => btn0,
            flap  => flap_req,
            hits  => display,
    
            red   => S_red,
            green => S_green,
            blue  => S_blue
        );
    
    --instantiations from labs
    vga_driver : vga_sync
    PORT MAP(--instantiate vga_sync component
        pixel_clk => pxl_clk, 
        red_in => S_red & "000", 
        green_in => S_green & "000", 
        blue_in => S_blue & "000", 
        red_out => VGA_red, 
        green_out => VGA_green, 
        blue_out => VGA_blue, 
        pixel_row => S_pixel_row, 
        pixel_col => S_pixel_col, 
        hsync => VGA_hsync, 
        vsync => S_vsync
    );
    VGA_vsync <= S_vsync; 
        
    clk_wiz_0_inst : clk_wiz_0
    port map (
      clk_in1 => clk_in,
      clk_out1 => pxl_clk
    );
    
     -- Counter for 7-seg mux
    PROCESS(clk_in)
    BEGIN
        IF rising_edge(clk_in) THEN
            count <= count + 1;
        END IF;
    END PROCESS;
    
    led_mpx <= count(19 DOWNTO 17);

    
    led1 : leddec16
    PORT MAP(
      dig => led_mpx, data => display, 
      anode => SEG7_anode, seg => SEG7_seg
    );

END Behavioral;
    
    
    
    
    
    

