# frozen_string_literal: true

module SpaceInvaders
  class LargeInvader < Invader
    initialize_pattern(
      <<~PATTERN
        --o-----o--
        ---o---o---
        --ooooooo--
        -oo-ooo-oo-
        ooooooooooo
        o-ooooooo-o
        o-o-----o-o
        ---oo-oo---
      PATTERN
    )
  end
end
