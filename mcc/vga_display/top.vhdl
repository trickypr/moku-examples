library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- Defines VGA timing constants and instantiates the core logic.
-- Configure the output logic at the end of this module to change the pinout,
-- including using different colour channels.

architecture Behavioural of CustomWrapper is

  ------------------------------------------
  --This is the specification to run the screen. 640*480 75fps
  CONSTANT H_total : INTEGER  :=800;
  CONSTANT V_total : INTEGER  :=525;

  CONSTANT H_Display : INTEGER  :=640;
  CONSTANT V_Display : INTEGER  :=480;

  CONSTANT H_Front_Porch : INTEGER :=16;
  CONSTANT H_sync_pulse : INTEGER :=96;
  CONSTANT H_Back_Porch : INTEGER :=48;
    
  CONSTANT V_Front_Porch : INTEGER :=11;
  CONSTANT V_sync_pulse : INTEGER :=2;
  CONSTANT V_Back_Porch : INTEGER :=32;
  ------------------------------------------
  ------------------------------------------
  COMPONENT Frame_Block is
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
      --Inputs
      Data_Clock : in std_logic;
      Input_Data : in signed(15 DOWNTO 0);
      Input_Data_Downsampling : in unsigned(31 DOWNTO 0);

      --Outputs
      --H,V sync
      H_sync : out std_logic;
      V_sync : out std_logic;
      --Pixel Data
      Data_Red : out unsigned(7 DOWNTO 0);
      Data_Green : out unsigned(7 DOWNTO 0);
      Data_Blue : out unsigned(7 DOWNTO 0)
    );
  end COMPONENT;
  ------------------------------------------
  ------------------------------------------
  --Data Signals
  signal V_sync : std_logic; --Active LOW
  signal H_sync : std_logic; --Active LOW

  --RGB signals. Is read as analog from 0-0.7V. 8 bit number meaning that 2.74mV per bit
  signal Data_Red : unsigned(7 DOWNTO 0);
  signal Data_Green : unsigned(7 DOWNTO 0);
  signal Data_Blue : unsigned(7 DOWNTO 0);
  ------------------------------------------

begin

  ------------------------------------------
  u_Frame_Block:Frame_Block
    generic map(
      H_total=>H_total,
      V_total=>V_total,
  
      H_Display=>H_Display,
      V_Display=>V_Display,
      
      H_Front_Porch=>H_Front_Porch,
      H_sync_pulse=>H_sync_pulse,
      H_Back_Porch=>H_Back_Porch,
        
      V_Front_Porch=>V_Front_Porch,
      V_sync_pulse=>V_sync_pulse,
      V_Back_Porch=>V_Back_Porch    
    )
    port map(     
      Data_Clock=>Clk, --Running at 31.25MHz
      H_sync=>H_sync,
      V_sync=>V_sync,
      Input_Data_Downsampling=>unsigned(Control2),
      Input_Data=>InputA,
      --Pixel Data
      Data_Red=>Data_Red,
      Data_Green=>Data_Green,
      Data_Blue=>Data_Blue
    );
  ------------------------------------------

  --Output Assignments
  OutputA(11 DOWNTO 0)<=signed( (Data_Red) & "1111");
  OutputB(11 DOWNTO 0)<=signed(Data_Blue & "1111");
  OutputC(0)<=H_sync;
  OutputC(1)<=V_sync;

end architecture;
