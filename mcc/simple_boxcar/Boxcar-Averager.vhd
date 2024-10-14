library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

entity BoxcarAverager is
port(
  Clk:  in std_logic;
  Reset: in std_logic;
  InputA: in signed (15 downto 0);
  InputB: in signed (15 downto 0);
  OutputA: out signed (15 downto 0);
  OutputB: out signed (15 downto 0));

end BoxcarAverager;

architecture SignalProcessing of BoxcarAverager is
	constant logGateLength : integer := 3;
	constant logAvgLength : integer := 3;

	type storageArrayGate is array (0 to 2**logGateLength-1) of signed(15 downto 0);
    type storageArrayOut is array (0 to 2**logAvgLength-1) of signed(15 downto 0);
	type t_State is (waitForTrigger,triggered);
    
    signal State : t_State := waitForTrigger;
    
    signal previousInputB : signed(15 downto 0):= (others => '0');
    
	signal eventDataArray : storageArrayGate:= (others=>(others=>'0'));
    signal eventSum : signed (16+logGateLength-1 downto 0):= (others => '0');
    signal eventCounter : integer := 0;
    signal eventAveraged : signed (15 downto 0):= (others => '0');
    
    signal eventAverageOut : signed (15 downto 0):= (others => '0');
    signal eventAverageOutUpdated : std_logic := '0';
    
    
    signal outputDataArray : storageArrayOut:= (others=>(others=>'0'));
    signal outputSum : signed (16+logAvgLength-1 downto 0):= (others => '0');
    
    procedure AverageDataArrayGate(signal rollingArray : inout storageArrayGate;
    						   signal sumdata : inout signed (16+logGateLength-1 downto 0);
                               signal counter : inout integer;
                               signal ADCvalue : in signed (15 downto 0);
                               signal averaged : out signed (15 downto 0)) is
    begin
        rollingArray <= ADCvalue&rollingArray(0 to 2**logGateLength-2);
        sumdata <= sumdata + ADCvalue - rollingArray(2**logGateLength-1);
    	averaged <= sumdata(16+logGateLength-1 downto logGateLength);
        counter <= counter + 1;  
    end procedure;
    
    procedure AverageDataArrayOut(signal rollingArray : inout storageArrayOut;
    						   signal sumdata : inout signed (16+logAvgLength-1 downto 0);
                               signal ADCvalue : in signed (15 downto 0)) is
    begin
        rollingArray <= ADCvalue&rollingArray(0 to 2**logAvgLength-2);
        sumdata <= sumdata + ADCvalue - rollingArray(2**logAvgLength-1);
    end procedure;


begin
	process(Clk) is
	begin
        if rising_edge(Clk) then
            if Reset then
                eventAverageOutUpdated <= '0';
                previousInputB <= (others => '0');
                State <= waitForTrigger;
            else
                case State is
                    when waitForTrigger =>
                        eventAverageOutUpdated <= '0';
                        if (InputB > to_signed(2000, InputB'length)) and (previousInputB < to_signed(2000, previousInputB'length)) then
                            State <= triggered;
                            eventCounter <= 0;
                            eventSum <= (others => '0');
                            eventDataArray <= (others=>(others=>'0'));
                        end if;
                        previousInputB <= InputB;
                        
                    when triggered =>
                        AverageDataArrayGate(eventDataArray,eventSum, eventCounter, InputA, eventAveraged);
                        if eventCounter = 2**logGateLength+1 then
                            eventAverageOut <= eventAveraged;
                            eventAverageOutUpdated <= '1';
                            State <= waitForTrigger;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    process(Clk) is
    begin
        if rising_edge(Clk) then
          if eventAverageOutUpdated then
              AverageDataArrayOut(outputDataArray, outputSum, eventAverageOut);
          end if;
        end if;
    end process;

    OutputA <= outputSum(16+logAvgLength-1 downto logAvgLength);

end SignalProcessing;
