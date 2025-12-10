--MODIFY THIS FILE FOR OUR PROJECT: 
--need to get AUDIO INPUT to lead to AUDIO PEAK =1

--DAC IF FILE REPURPOSED INTO AUDIO PEAK FILE
--note: file is named dac_if but we do not use dac stuff
--      ..just keeping the name as-is to not break flap.vhd

--process: 
--1) get audio input from onboard mic (PDM microphone)
--2) sample the audio at a rate to get a digital value
--3) compare amplitude to threshold.

--pdm module should deserialize the pdm bitstream into 16 bit samples
--then we can detect amplitude spikes
--and then turn the 16 bit sample to audio_peak = '1' or = '0'

--references:
--pdmdes.vhd: https://github.com/karlsheng99/CPE487_DigitalSystemDesign/blob/master/project/AudioVisualEqualizer/AudioVisualEqualizer.srcs/sources_1/new/PdmDes.vhd
--https://digilent.com/reference/programmable-logic/nexys-a7/reference-manual?srsltid=AfmBOoo99IRTWQ3HSlQ0GkphzQbwDRcr8Cd6Fa3kmbknETXNy2gYOeAk

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY dac_if IS
	port (
	   clk : in std_logic;
	   mic_data : in std_logic;
	   mic_clk : out std_logic;
	   audio_peak : out std_logic
   );
end dac_if;
	   
ARCHITECTURE Behavioral OF dac_if IS
    --pdm deseralizer signals:
    signal sample_ready : std_logic;
    signal sample_data : std_logic_vector(15 downto 0);
    --signal audio_level : unsigned(15 downto 0) := (others => '0');
    --threshold of loudness:
    constant threshold : unsigned(15 downto 0) := to_unsigned(3000, 16);
    
   --instantiate pdm mic deserializer
    component PdmDes is
        generic(
            C_NR_OF_BITS : integer := 16;
            C_SYS_CLK_FREQ_MHZ : integer := 75;
            C_PDM_FREQ_HZ : integer := 2000000
        );
        port(
           clk_i : in std_logic;
           en_i : in std_logic; -- Enable deserializing (during record)
              
           done_o : out std_logic; -- Signaling that 16 bits are deserialized
           data_o : out std_logic_vector(15 downto 0); -- output deserialized data
              
              -- PDM
           pdm_m_clk_o : out std_logic; -- Output M_CLK signal to the microphone
           pdm_m_data_i : in std_logic; -- Input PDM data from the microphone
           pdm_lrsel_o : out std_logic; -- Set to '0', therefore data is read on the positive edge
           pdm_clk_rising_o : out std_logic -- Signaling the rising edge of M_CLK, used by the MicDisplay
                                               -- component in the VGA controller
           );
      end component;
   
begin       
--deserializer
       pdm_inst : PdmDes
       generic map(
            C_NR_OF_BITS => 16,
            C_SYS_CLK_FREQ_MHZ => 75,
            C_PDM_FREQ_HZ => 2000000
        )
        port map(
           clk_i => clk,
           en_i => '1', -- Enable deserializing (during record)
              
           done_o => sample_ready, -- Signaling that 16 bits are deserialized
           data_o => sample_data, -- output deserialized data
              
              -- PDM
           pdm_m_clk_o => mic_clk, -- Output M_CLK signal to the microphone
           pdm_m_data_i => mic_data, -- Input PDM data from the microphone
           pdm_lrsel_o => open, -- Set to '0', therefore data is read on the positive edge
           pdm_clk_rising_o => open-- Signaling the rising edge of M_CLK, used by the MicDisplay
                                               -- component in the VGA controller
           );
      
    --peak detector PROCESS:
        process(clk)
            variable temp_signed : signed(15 downto 0);
            variable temp_abs : unsigned(15 downto 0);
        begin
            if rising_edge(clk) then
            --updating audio level when new sample arrives
                if sample_ready = '1' then
                    --take absolute value of sample
                    temp_signed := signed(sample_data);
                    if temp_signed < 0 then
                        temp_abs := unsigned(-temp_signed);
                    else
                        temp_abs := unsigned(temp_signed);
                    end if;
                --compare it against the threshold
                    if temp_abs > threshold then
                        audio_peak <= '1';
                    else
                        audio_peak <= '0';
                end if;
           end if;
        end if;
     end process;
    
END Behavioral;
