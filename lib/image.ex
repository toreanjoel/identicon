defmodule Identicon.Image do
  @moduledoc """
    This is the image struct used to keep the structure of an image
    that will be made through the identicon invocation

    See: [sub-section] (./Identicon.html) for the module usage
  """
  defstruct hex: nil, color: nil, grid: nil, pixel_map: nil
end