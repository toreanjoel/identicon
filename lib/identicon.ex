# what is the difference between using a module Name vs :atom as library?
# - this is an erlang library method
defmodule Identicon do
  @moduledoc """
    Uses and input to general an identicon for the string passed and create and save
    an image binary to disk based off the identicon generated through input

    Entry point is the `main` function
  """

  @doc """
    The entry point to the Identicon module. The input is a string and piped through functions.
    The functions all have their own doc and no test will need to be done here other than the okay response.

  ## Examples
      input
      |> hash_input
      |> pick_color
      |> build_grid
      |> filter_odd_squares
      |> build_pixel_map
      |> compute_image
      |> save_image(input)

      iex> Identicon.main("test")
      {:ok, "Successfully create file, see path: ./test.png"}

  """
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> compute_image
    |> save_image(input)

    #response success run
    {:ok, "Successfully create file, see path: ./#{input}.png"}
  end

  @doc """
    Take a file binary and a file name and use the File write method to save the file to disk.
    The file here in question will be the Erlang image binary made through the pixel map

  ## Example
      test here
  """
  def save_image(image, file_name) do
    File.write("#{file_name}.png", image)
  end

  @doc """
    Take pixel map and color from the image struct and create an an image in memory through
    Erlang graphix drawing methods, the dementions being 250x250 and then use the pixel map
    to pull out the start and stop drawing points for a fill over an enum with the full

    see: https://www.erlang.org/docs/17/man/egd.html

    Render and return an image binary that can be saved

  ## Examples
      iex>Identicon.compute_image(
      iex>%Identicon.Image{
      iex>  color: {9, 143, 107},
      iex>  grid: [
      iex>    {70, 6},
      iex>    {70, 8},
      iex>    {202, 12},
      iex>    {222, 15},
      iex>    {78, 16},
      iex>    {78, 18},
      iex>    {222, 19},
      iex>    {38, 20},
      iex>    {180, 22},
      iex>    {38, 24}
      iex>  ],
      iex>  hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180],
      iex>  pixel_map: [
      iex>    {{50, 50}, {100, 100}},
      iex>    {{150, 50}, {200, 100}},
      iex>    {{100, 100}, {150, 150}},
      iex>    {{0, 150}, {50, 200}},
      iex>    {{50, 150}, {100, 200}},
      iex>    {{150, 150}, {200, 200}},
      iex>    {{200, 150}, {250, 200}},
      iex>    {{0, 200}, {50, 250}},
      iex>    {{100, 200}, {150, 250}},
      iex>    {{200, 200}, {250, 250}}
      iex>  ]
      iex>})
  """
  def compute_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn {start, stop} ->
        :egd.filledRectangle(image, start, stop, fill)
      end
    )

    :egd.render(image)
  end

  # we need to build a start and end point for the pixels on an image with their color
  # this is used along side the drawing on a image in mem made by erlang :egd
  @doc """
    Take image struct grid list, create pixel map that will be a tuple of 2 value tuples.
    This will contain the top_left pixels and bottom_right pixels relative to 0,0 that will come
    through an image creation from erlang. This image will be based on a 250x250 size and
    50x50 pixel block (5 per row and height).

    Return pixel list property with tuple of 2 value tuples

  ## Examples
      iex> Identicon.build_pixel_map(
      iex> %Identicon.Image{
      iex>   color: {9, 143, 107},
      iex>   grid: [
      iex>     {70, 6},
      iex>     {70, 8},
      iex>     {202, 12},
      iex>     {222, 15},
      iex>     {78, 16},
      iex>     {78, 18},
      iex>     {222, 19},
      iex>     {38, 20},
      iex>     {180, 22},
      iex>     {38, 24}
      iex>   ],
      iex>   hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180],
      iex>   pixel_map: nil
      iex> })
      %Identicon.Image{
        color: {9, 143, 107},
        grid: [
          {70, 6},
          {70, 8},
          {202, 12},
          {222, 15},
          {78, 16},
          {78, 18},
          {222, 19},
          {38, 20},
          {180, 22},
          {38, 24}
        ],
        hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180],
        pixel_map: [
          {{50, 50}, {100, 100}},
          {{150, 50}, {200, 100}},
          {{100, 100}, {150, 150}},
          {{0, 150}, {50, 200}},
          {{50, 150}, {100, 200}},
          {{150, 150}, {200, 200}},
          {{200, 150}, {250, 200}},
          {{0, 200}, {50, 250}},
          {{100, 200}, {150, 250}},
          {{200, 200}, {250, 250}}
        ]
      }
  """
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    # gen new prop for each grid item top - left and bottom right
    pixel_map = Enum.map(grid, fn {_code, index} ->
        horizontal = Kernel.rem(index, 5) * 50
        vertical = Kernel.div(index, 5) * 50

        top_left = {horizontal, vertical}
        bottom_right = {horizontal + 50, vertical + 50}

        {top_left, bottom_right}
      end
    )

    %Identicon.Image{image | pixel_map: pixel_map }
  end

  @doc """
    Take encrypted input as hex list, chunk it down in groups of 3 (omitting the remainders)
    Run each row chunk through `mirror_row` to concatinate first two idices.
    Flatted the chuncked multidementional list then make sure each item in the list is not 1 item
    but a 2 pair tuple containing the hex as well as the index they are in the list.

    Return Image struct with the grid property tuple lists
  ## Example
      iex> Identicon.build_grid(
      iex> %Identicon.Image{
      iex>  color: {9, 143, 107},
      iex>  grid: nil,
      iex>  hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180],
      iex>  pixel_map: nil
      iex> })
      %Identicon.Image{
        color: {9, 143, 107},
        grid: [
          {9, 0},
          {143, 1},
          {107, 2},
          {143, 3},
          {9, 4},
          {205, 5},
          {70, 6},
          {33, 7},
          {70, 8},
          {205, 9},
          {211, 10},
          {115, 11},
          {202, 12},
          {115, 13},
          {211, 14},
          {222, 15},
          {78, 16},
          {131, 17},
          {78, 18},
          {222, 19},
          {38, 20},
          {39, 21},
          {180, 22},
          {39, 23},
          {38, 24}
        ],
        hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180],
        pixel_map: nil
      }
  """
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid = hex
      |> Enum.chunk_every(3)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index

    # we need to return the struct at the end here updated
    %Identicon.Image{image | grid: grid}
  end

  @doc """
    Take in a list and match against the first and second index. Make a new list
    containing the first and second items and concatinate the new list at the end against
    the original list so we can have the list mirrored against the first two idices

  ## Examples
      Test here
  """
  def mirror_row([first, second | _tail] = row) do
    row ++ [second, first]
  end

  @doc """
    Take in the image struct and pull out the grid property, this property is a list of lists.
    Each list item in the grid list is then iterated over and because each is a 2 pair tuple item in the
    role we iterate over with the hex (value) and index, we remove all items with a filter.

    This will make sure we are left with a grid list of rows that only contain tuples of the value/index
    of items in a row that are even (this is how we determine the block that will be colored)

    Return updated image struct grid
  ## Example
      iex> Identicon.filter_odd_squares(
      iex> %Identicon.Image{
      iex>   color: {9, 143, 107},
      iex>   grid: [
      iex>     {9, 0},
      iex>     {143, 1},
      iex>     {107, 2},
      iex>     {143, 3},
      iex>     {9, 4},
      iex>     {205, 5},
      iex>     {70, 6},
      iex>     {33, 7},
      iex>     {70, 8},
      iex>     {205, 9},
      iex>     {211, 10},
      iex>     {115, 11},
      iex>     {202, 12},
      iex>     {115, 13},
      iex>     {211, 14},
      iex>     {222, 15},
      iex>     {78, 16},
      iex>     {131, 17},
      iex>     {78, 18},
      iex>     {222, 19},
      iex>     {38, 20},
      iex>     {39, 21},
      iex>     {180, 22},
      iex>     {39, 23},
      iex>     {38, 24}
      iex>   ],
      iex>   hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180],
      iex>   pixel_map: nil
      iex> })
      %Identicon.Image{
        color: {9, 143, 107},
        grid: [
          {70, 6},
          {70, 8},
          {202, 12},
          {222, 15},
          {78, 16},
          {78, 18},
          {222, 19},
          {38, 20},
          {180, 22},
          {38, 24}
        ],
        hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180],
        pixel_map: nil
      }
  """
  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid_even = Enum.filter(grid,
      fn {value, _index} ->
        Kernel.rem(value, 2) == 0
      end
    )

    # update the grid
    %Identicon.Image{image | grid: grid_even}
  end

  @doc """
    Takes the input of the user and hases the value through the erlang crypto package
    with the mdf encryption, the value is then piped through the bin_to_list which converts
    the hased encrypted binary response to a list of of hex codes

    We use this list to remove the last value off the list as we dont need it for the identicon
    generation (the index will be more than what is required to generate it)

    Return image struct with added hex values
  ## Examples
      iex> Identicon.hash_input("test")
      %Identicon.Image{
        color: nil,
        grid: nil,
        hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180],
        pixel_map: nil
      }
  """
  def hash_input(input) do
    # convert the string into a series of unique numbers
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list
    |> List.delete_at(-1) # passes binary as first arity, runs remove at the end

    %Identicon.Image{hex: hex}
  end

  @doc """
    Take an image struct and add a color property that takes the first 3 indices of the
    image hex property as the rgb values inside of a tuple property for the color i.e {r, g, b}

    Return Image struct with color property
  ## Examples
      iex> Identicon.pick_color(
      iex> %Identicon.Image{
      iex>   color: nil,
      iex>   grid: nil,
      iex>   hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180],
      iex>   pixel_map: nil
      iex> })
      %Identicon.Image{
        color: {9, 143, 107},
        grid: nil,
        hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180],
        pixel_map: nil
      }
  """
  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image_struct) do
    %Identicon.Image{image_struct | color: {r, g, b}}
  end
end
