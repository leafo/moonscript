
import P, C, S from require "lpeg"

-- captures an indentation, returns indent depth
Indent = C(S"\t "^0) / (str) ->
  with sum = 0
    for v in str\gmatch "[\t ]"
      switch v
        when " "
          sum += 1
        when "\t"
          sum += 4


-- causes pattern in progress to be rejected
-- can't have P(false) because it causes preceding patterns not to run
Cut = P -> false

-- ensures finally runs regardless of whether pattern fails or passes
ensure = (patt, finally) ->
	patt * finally + finally * Cut

{ :Indent, :Cut, :ensure }
