project( convert_img )
find_package( OpenCV REQUIRED )
add_executable( convert_img convert_img )
target_link_libraries( convert_img ${OpenCV_LIBS} )
