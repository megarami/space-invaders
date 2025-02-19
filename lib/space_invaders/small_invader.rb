# frozen_string_literal: true

module SpaceInvaders
  class SmallInvader < Invader
    initialize_pattern(
      <<~PATTERN
        ---oo---
        --oooo--
        -oooooo-
        oo-oo-oo
        oooooooo
        --o--o--
        -o-oo-o-
        o-o--o-o
      PATTERN
    )
  end
end
