import cv2
from ultralytics import YOLO

model = YOLO("/home/ahmedmama/Documents/Stage/nigma/models/best.pt")

cam = cv2.VideoCapture(0)

while cam.isOpened():
    ret, frame = cam.read()
    if not ret:
        break

    # Prédiction
    results = model.predict(frame, conf=0.5, verbose=False)

    # Dessiner les bounding boxes
    annotated_frame = results[0].plot()

    # Affichage
    cv2.imshow("Detection", annotated_frame)

    if cv2.waitKey(1) & 0xFF == 27:  # ESC
        break

cam.release()
cv2.destroyAllWindows()