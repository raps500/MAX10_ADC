
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UARTRX_tb is

end UARTRX_tb;

architecture logic of UARTRX_tb is
    component UARTRX is
        port (
            clk_in      : in  std_logic; -- 50 MHz clock
            data_o      : out  std_logic_vector(7 downto 0);
            data_rdy_o  : out  std_logic;
            data_ovr_o  : out  std_logic;
            data_ack_in : in std_logic;
            bits_o      : out  std_logic_vector(7 downto 0);
            bit_cnt_o   : out  std_logic_vector(7 downto 0);
            rx_in       : in std_logic
        );
        end component UARTRX;
         
        signal clk_10MHz    : std_logic;
        signal clk_12MHz    : std_logic;
        signal clk_50MHz    : std_logic;
        signal clk_1MHz     : std_logic;
        signal resetn       : std_logic; -- pll locked used as reset signal, reset active low
        signal tx_data      : std_logic_vector(7 downto 0);
        signal rx_data      : std_logic_vector(7 downto 0);

        signal rx_in        : std_logic := '1';
        signal tx_start     : std_logic;
        signal tx_busy      : std_logic;
        signal rx_ready     : std_logic;
        signal rx_overrun   : std_logic;
        signal rx_ack       : std_logic;
        signal bits         : std_logic_vector(7 downto 0);
        signal bit_cnt      : std_logic_vector(7 downto 0);
        signal d5           : std_logic_vector(3 downto 0);
     
begin

    
    irx : UARTRX port map(
        clk_in      => clk_50MHz,
        data_o      => rx_data,
        data_rdy_o  => rx_ready,
        data_ovr_o  => rx_overrun,
        data_ack_in => rx_ack,
        bits_o      => bits,
		bit_cnt_o   => bit_cnt,
		
        rx_in       => rx_in
    );
    
    process -- clk 50 MHz
        begin
            clk_50MHz        <= '0';
            wait for 10 ns;
            clk_50MHz        <= '1';
            wait for 10 ns;
        end process;
    -- RX
    process 
        begin
            rx_in  <= '1';
            wait for 777 ns;
            rx_in <= '0';
            wait for 1 us;
            rx_in <= '1';
            wait for 1 us;
            rx_in <= '0';
            wait for 1 us;
            rx_in <= '0';
            wait for 1 us;
            rx_in <= '0';
            wait for 1 us;
            rx_in <= '0';
            wait for 1 us;
            rx_in <= '0';
            wait for 1 us;
            rx_in <= '0';
            wait for 1 us;
            rx_in <= '0';
            wait for 1 us;
            rx_in <= '1';
            wait for 1 us;
            rx_in <= '1';
            wait;
        end process;

        
end architecture logic;




