library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- The embedded "Data Block" implements the core Oscilloscope function and outputs the voltage recorded at the current horizontal
-- position. This block converts that to colour values of specific pixels for display on the screen.

ENTITY Display_Block is
  generic(
    H_Display : INTEGER;
    V_Display : INTEGER
  );
  port(
    --Inputs
    --Counters
    H_counter : in unsigned(15 DOWNTO 0);
    V_counter : in unsigned(15 DOWNTO 0);
    Data_Clock : in std_logic;
    --Input Data
    Input_Data : in signed(15 DOWNTO 0);
    Input_Data_Downsampling : in unsigned(31 DOWNTO 0);
    
    --Outputs
    --Pixel Data
    Data_Red : out unsigned(7 DOWNTO 0);
    Data_Green : out unsigned(7 DOWNTO 0);
    Data_Blue : out unsigned(7 DOWNTO 0)
  );
end Display_Block;

ARCHITECTURE structure of Display_Block is
  ------------------------------------------
  COMPONENT Data_Block is
    generic(
      H_Display : INTEGER;
      V_Display : INTEGER
    );
      port(
      Data_Clock : in std_logic;
      Input_Data : in signed(15 DOWNTO 0);  
      Input_Data_Downsampling : in unsigned(31 DOWNTO 0);
      H_counter : in unsigned(15 DOWNTO 0);
        
      Output_Value : out signed(8 DOWNTO 0)
    );
  end COMPONENT;
  ------------------------------------------
  ------------------------------------------
  signal Output_Value : signed(8 DOWNTO 0);
  signal Output_Value_adjusted : unsigned(8 DOWNTO 0);
  ------------------------------------------

  begin
    ------------------------------------------
    u_Data_Block:Data_Block
      generic map(
        H_Display=>H_Display,
        V_Display=>V_Display
      )
      port map(
        Data_Clock=>Data_Clock,
        Input_Data=>Input_Data,  
        Input_Data_Downsampling=>Input_Data_Downsampling,
        H_counter=>H_counter,
          
        Output_Value=>Output_Value
      );
      ------------------------------------------
      
    process(H_counter,V_counter) 
      begin
    
        if (H_counter<H_display-1) and (V_counter<V_display-1) then --Wrapping the counter to display values only (excludes porches etc.)

          Output_Value_adjusted<=unsigned(240-Output_Value); --Setting the centre of the monitor as 0

          -- Each data point is rendered as a 16-pixel high line. A more advanced implementation would trace a line between
          -- adjacent points.
          if Output_Value_adjusted>V_counter-"1000" and Output_Value_adjusted<V_counter+"1000" then
            Data_Red<="11111111";
            Data_Blue<="11111111";
            Data_Green<="11111111";
          else
            Data_Red<="01111111"; --No signal detected
            Data_Blue<="00000000";
            Data_Green<="00000000";
          end if;
            
        else
          Data_Red<="00000000"; --When not in the Display area, no need to output anything.
          Data_Blue<="00000000";
          Data_Green<="00000000";
        end if;

    end process;
          
end structure;
