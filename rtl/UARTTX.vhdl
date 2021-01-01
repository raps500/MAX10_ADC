--
-- simple UART, bit clock is the clk_in
--
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UARTTX is
	port (
		clk_in      : in  std_logic                     := '0'; -- 50 MHz clock
		data_in     : in  std_logic_vector(7 downto 0)  := (others => '0');
		start_in    : in  std_logic                     := '0';
        tx_busy_o   : out std_logic;       
		tx_o        : out std_logic                         
	);
end entity UARTTX;

architecture rtl of UARTTX is

    signal state    : integer range 0 to 15 := 0;
    signal txbuff   : std_logic_vector(10 downto 0) := "10000000001";
    signal bit_cnt  : integer range 0 to 63 := 0;
    signal tx_busy  : std_logic := '0';
    
begin
    tx_o <= txbuff(0);
    tx_busy_o <= tx_busy;
    
    process(clk_in) 
    begin
        if (rising_edge(clk_in)) then
            
            if bit_cnt = 0 then
                case state is
                    when 0 => -- wait for start condition
                        if start_in = '1' then 
                            state <= 1;
                            txbuff <= '1' & data_in & "01"; -- stop bit, data & start condition.
                            tx_busy <= '1';
                        end if;
                    when 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11  =>
                        txbuff <= '1' & txbuff(10 downto 1); -- shift
                        state <= state + 1;
                    when others =>
                        state <= 0;
                        tx_busy <= '0';
                end case;
            end if;
            
            if state /= 0 then
                if bit_cnt = 0 then
                    bit_cnt <= 49;
                else
                    bit_cnt <= bit_cnt - 1;
                end if;
            else
                bit_cnt <= 0;
            end if;
        end if;
    end process;
    
    
end architecture;
