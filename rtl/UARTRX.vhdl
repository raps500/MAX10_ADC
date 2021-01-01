--
-- simple UART receiver, bit clock is the clk_in divided by 50
--
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UARTRX is
	port (
		clk_in      : in  std_logic                     := '0'; -- 50 MHz clock
		data_o      : out  std_logic_vector(7 downto 0);
		data_rdy_o  : out  std_logic;
		data_ovr_o  : out  std_logic;
        data_ack_in : in std_logic;
        
        bits_o      : out  std_logic_vector(7 downto 0);
		bit_cnt_o   : out  std_logic_vector(7 downto 0);
        
		rx_in       : in std_logic                           
	);
end entity UARTRX;

architecture logic of UARTRX is

    signal state  : integer range 0 to 15 := 0;
    signal rxbuff : std_logic_vector(7 downto 0) := "00000000";
    signal bit_cnt : integer range 0 to 63 := 0;
    signal old_rx : std_logic := '0';
    signal samples : std_logic_vector(2 downto 0) := "000";
    signal majority : std_logic;
    signal data_rdy : std_logic := '0';
    signal data_ovr : std_logic := '0';

    signal bits     : integer range 0 to 255 := 0;
    
    
begin

    majority <= (samples(0) and samples(1)) or (samples(1) and samples(2)) or (samples(0) and samples(2));
    data_rdy_o <= data_rdy;
    data_ovr_o <= data_ovr;
    data_o <= rxbuff(7 downto 0);
    
    bits_o <= std_logic_vector(to_unsigned(bits, 8));
    bit_cnt_o <= std_logic_vector(to_unsigned(bit_cnt, 8));
     
    process(clk_in) 
    begin
        if (rising_edge(clk_in)) then
            -- sampling
            old_rx <= rx_in;
                       
            if state = 0 then -- wait for start condition
                bit_cnt <= 0;
                if old_rx = '1' and rx_in = '0' then 
                    state <= 1;
                    bits <= (bits + 1) mod 256;
                end if;
            else
                if bit_cnt = 49 then
                    bit_cnt <= 0;
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
            end if;            
            
            if bit_cnt = 49 then
                case state is
                    when 0 => null; -- wait for start condition

                    when 1 => -- start bit
                            state <= state + 1;
                    when 2 | 3 | 4 | 5 | 6 | 7 | 8 =>                   
                        rxbuff <= majority & rxbuff(7 downto 1); -- shift
                        state <= state + 1;
                        bits <= (bits + 1) mod 256;
                    when others => -- last bit
                        rxbuff <= majority & rxbuff(7 downto 1); -- shift
                        state <= 0;
                        if data_rdy = '1' then
                            data_ovr <= '1';
                        end if;
                        data_rdy <= '1';
                end case;
            end if;
            if bit_cnt = 15 then
                samples(0) <= old_rx;
            end if;
            if bit_cnt = 25 then
                samples(1) <= old_rx;
            end if;
            if bit_cnt = 35 then
                samples(2) <= old_rx;
            end if;
            -- data_rdy
            if data_ack_in = '1' then 
                data_rdy <= '0';
            end if;
        end if;
    end process;
    
    
end architecture;
