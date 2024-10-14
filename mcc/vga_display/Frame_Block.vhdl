library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- Generates the VGA control signals, both to the display (sync signals) and for
-- the rest of the code (pixel location).
-- Instantiates the display logic that generates the image to be displayed

ENTITY Frame_Block is
  generic(
    H_total : INTEGER;
    V_total : INTEGER;

    H_Display : INTEGER;
    V_Display : INTEGER;
    
    H_Front_Porch : INTEGER;
    H_sync_pulse : INTEGER;
    H_Back_Porch : INTEGER;
      
    V_Front_Porch : INTEGER;
    V_sync_pulse : INTEGER;
    V_Back_Porch : INTEGER    
  );
  port(
    --Input
    Data_Clock : in std_logic;
    Input_Data : in signed(15 DOWNTO 0);
    Input_Data_Downsampling : in unsigned(31 DOWNTO 0);

    --Output
    H_sync : out std_logic;
    V_sync : out std_logic;
    --Pixel Data
    Data_Red : out unsigned(7 DOWNTO 0);
    Data_Green : out unsigned(7 DOWNTO 0);
    Data_Blue : out unsigned(7 DOWNTO 0)
  );

end Frame_Block;
  
ARCHITECTURE structure of Frame_Block is

  ------------------------------------------
  --Data block function. Allows me to output data from array.
  COMPONENT Display_Block is
    generic(
      H_Display : INTEGER;
      V_Display : INTEGER
    );
    port(
      --Counters
      H_counter : in unsigned(15 DOWNTO 0);
      V_counter : in unsigned(15 DOWNTO 0);
      --Input Data
      Input_Data : in signed(15 DOWNTO 0);
      Input_Data_Downsampling : in unsigned(31 DOWNTO 0);
      Data_Clock : in std_logic;
  
      --Pixel Data
      Data_Red : out unsigned(7 DOWNTO 0);
      Data_Green : out unsigned(7 DOWNTO 0);
      Data_Blue : out unsigned(7 DOWNTO 0)
    );
  end COMPONENT;
  ------------------------------------------
  ------------------------------------------  
  signal H_counter : unsigned(15 DOWNTO 0);
  signal V_counter : unsigned(15 DOWNTO 0);
  ------------------------------------------

  begin

    ------------------------------------------
    --Port maps
    u_Display_Block:Display_Block
      generic map(
        H_Display=>H_Display,
        V_Display=>V_Display
      )
      port map(
        --Counters
        Data_Clock=>Data_Clock,
        H_counter=>H_counter,
        V_counter=>V_counter,
        Input_Data=>Input_Data,
        Input_Data_Downsampling=>Input_Data_Downsampling,
        
        --Pixel Data
        Data_Red=>Data_Red,
        Data_Green=>Data_Green,
        Data_Blue=>Data_Blue
      );
    ------------------------------------------
  
      
    process(Data_Clock)
      begin 
        if rising_edge(Data_Clock) then
  
          --Counter for the current pixel location
          if (H_counter<H_total-1) then
            H_counter <= H_counter+1;
          else
            H_counter <="0000000000000000";
            if (V_counter<V_total-1) then 
              V_counter <= V_counter+1;
            else 
              V_counter <="0000000000000000";
            end if;
          end if;
              
          --Horizontal Porch
          if H_counter<(H_Display + H_Front_Porch) OR H_counter >= (H_Display + H_Front_Porch + H_sync_pulse) then
            H_sync<='1'; --Active Low
          else 
            H_sync<='0'; 
          end if;
            
          --Vertical Porch
          if V_counter<(V_Display + V_Front_Porch) OR V_counter >= (V_Display + V_Front_Porch + V_sync_pulse) then
            V_sync<='1'; --Active Low
          else 
            V_sync<='0'; 
          end if;
            
        end if;
   
    end process;

end structure;
