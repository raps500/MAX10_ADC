

--
-- simple 7 segments CLUT
--
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CLUT7SEG is
	port (
		digit_in    : in  std_logic_vector(3 downto 0);
		segs_o      : out std_logic_vector(7 downto 0)
	);
end entity CLUT7SEG;

architecture logic of CLUT7SEG is

    
begin
    segs_o <=   "11000000" when digit_in = X"0" else
                "11111001" when digit_in = X"1" else	-- ---t----
                "10100100" when digit_in = X"2" else 	-- |	  |
                "10110000" when digit_in = X"3" else 	-- lt	 rt
                "10011001" when digit_in = X"4" else 	-- |	  |
                "10010010" when digit_in = X"5" else 	-- ---m----
                "10000010" when digit_in = X"6" else 	-- |	  |
                "11111000" when digit_in = X"7" else 	-- lb	 rb
                "10000000" when digit_in = X"8" else 	-- |	  |
                "10011000" when digit_in = X"9" else 	-- ---b----
                "10001000" when digit_in = X"A" else
                "10000011" when digit_in = X"B" else
                "11000110" when digit_in = X"C" else
                "10100001" when digit_in = X"D" else
                "10000110" when digit_in = X"E" else
                "10001110";
        
end architecture;