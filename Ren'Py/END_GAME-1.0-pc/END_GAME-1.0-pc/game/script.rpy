define bear = Character("Bear")

image bear = "images/bear.png"
image bg space = "images/space.jpg"

label start:

    scene bg space:
        zoom 1.5  # set the background
    with fade

    show bear at center:  # show bear image
        zoom 2.0
    with dissolve

    bear "Congratulations."
    bear "This is the end."
    bear "I am the final boss of the game"
    bear "Maybe 1HP were the friends we made along the way"
    return