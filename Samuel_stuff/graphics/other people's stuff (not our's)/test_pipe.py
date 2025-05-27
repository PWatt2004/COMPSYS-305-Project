pixel_col = 500
pipe_height = 100
pipe_width = 30
pixel_row = 70
pipe_x_pos = 520  # Change this value to test different positions

top_pipe_on = '1' if (
    pipe_x_pos > pixel_col 
    and pixel_col > pipe_x_pos - pipe_width 
    and pixel_row < pipe_height
) else '0'

print(top_pipe_on)
