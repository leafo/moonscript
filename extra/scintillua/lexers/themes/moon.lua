-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- moon lexer theme for Scintillua.

module('lexer', package.seeall)

colors = {
  green       = color('9F', 'FF', '98'), --
  blue        = color('94', '95', 'FF'), --
  light_blue  = color('98', 'D9', 'FF'), --
  red         = color('FF', '98', '98'), --
  bright_red  = color("F9", "26", "32"), --
  yellow      = color('FF', 'E8', '98'), --
  teal        = color('4D', '99', '99'),
  white       = color('FF', 'FF', 'FF'), --
  black       = color('2E', '2E', '2E'), --
  grey        = color('92', '92', '92'), --
  purple      = color('CB', '98', 'FF'), -- 
  orange      = color('FF', '92', '00'), --
  pink        = color("ED", "4E", "78"), --
}

style_nothing     = style {                                         }
style_char        = style { fore = colors.red,     bold      = true }
style_class       = style { fore = colors.light_blue, bold   = true }
style_comment     = style { fore = colors.grey,                     }
style_constant    = style { fore = colors.teal,    bold      = true }
style_definition  = style { fore = colors.red,     bold      = true }
style_error       = style { fore = colors.white, back = colors.bright_red, bold = true}
style_function    = style { fore = colors.white,   bold      = true }
style_keyword     = style { fore = colors.purple,  bold      = true }
style_number      = style { fore = colors.blue                      }
style_operator    = style { fore = colors.white,   bold      = true }
style_string      = style { fore = colors.yellow,  bold      = true }
style_preproc     = style { fore = colors.light_blue                }
style_tag         = style { fore = colors.teal,    bold      = true }
style_type        = style { fore = colors.green                     }
style_variable    = style { fore = colors.white,   italic    = true }
style_embedded    = style_tag..{ back = color('44', '44', '44')     }
style_identifier  = style_nothing

-- Default styles.
local font_face = '!Bitstream Vera Sans Mono'
local font_size = 12
if WIN32 then
  font_face = not GTK and 'Courier New' or '!Courier New'
elseif OSX then
  font_face = '!Monaco'
  font_size = 12
end
style_default = style{
  font = font_face,
  size = font_size,
  fore = colors.white,
  back = colors.black
}
style_line_number = style { fore = colors.black, back = colors.grey }
style_bracelight  = style { fore = color('66', '99', 'FF'), bold = true }
style_bracebad    = style { fore = color('FF', '66', '99'), bold = true }
style_controlchar = style_nothing
style_indentguide = style { fore = colors.grey, back = colors.white }
style_calltip     = style { fore = colors.white, back = color('44', '44', '44') }
