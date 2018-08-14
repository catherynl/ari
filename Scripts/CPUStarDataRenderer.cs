using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Precompute data used by the shader to accelerate rendering.
public class CPUStarDataRenderer : BaseStarDataRenderer {

  public override IEnumerator ComputeStarData()
  {
    SendProgress(0);

    // Create 1 large texture, then render smaller tiles into it.
    Texture2D tex = new Texture2D((int)imageSize, (int)imageSize, TextureFormat.RGBAFloat, false);

    // Random points on sphere surface to position stars.
    int tileSize = (int)imageSize / 2;
    List<StarPoint> starPoints = GenerateRandomStarsPoints(density, tileSize, tileSize);

    Vector2 origin = new Vector2(0, tileSize);

    SendProgress(0);

    Vector2 rotationOrigin = new Vector2(tileSize, tileSize);

    // Fill in the image.
    for (int yIndex = 0; yIndex < tileSize; yIndex++) {
      float yPercent = (float)yIndex / (float)(tileSize - 1);
      float yPosition = SphereUtility.PercentToHeight(yPercent);

      for (int xIndex = 0; xIndex < tileSize; xIndex++) {
        float anglePercent = (float)xIndex / (float)(tileSize - 1);
        float angle = SphereUtility.PercentToRadAngle(anglePercent);

        Vector3 currentSpot = SphereUtility.SphericalToPoint(yPosition, angle);

        // Closest star to current spot.
        StarPoint star = NearestStarPoint(currentSpot, starPoints);

        UnityEngine.Color c = new UnityEngine.Color(
          star.position.x,
          star.position.y,
          star.position.z,
          star.noise); // Noise value used to randomize each star.

        tex.SetPixel((int)origin.x + xIndex, (int)origin.y + yIndex, c);

        // Calculate the stars rotation.
        float xRotation;
        float yRotation;
        SphereUtility.CalculateStarRotation(star.position, out xRotation, out yRotation);

        UnityEngine.Color r = new UnityEngine.Color(
          xRotation,
          yRotation,
          0,
          1);

        tex.SetPixel((int)rotationOrigin.x + xIndex, (int)rotationOrigin.y + yIndex, r);
      }

      // Update the GUI progress bar.
      float totalProgress = (float)((yIndex + 1) * tileSize) / (float)(tileSize * tileSize);
      SendProgress(totalProgress);

      yield return null;
    }

    tex.Apply(false);

    SendCompletion(tex, true);

    yield break;
  }

  List<StarPoint> GenerateRandomStarsPoints(float density, int imageWidth, int imageHeight)
  {
    int numStars = Mathf.FloorToInt((float)imageWidth * (float)imageHeight * Mathf.Clamp(density, 0, 1));
    List<StarPoint> stars = new List<StarPoint>(numStars + 1);

    for (int i = 0; i < numStars; i++) {
      Vector3 pointOnSphere = UnityEngine.Random.onUnitSphere * sphereRadius;
      StarPoint star = new StarPoint(pointOnSphere,
        Random.Range(.5f, 1.0f),
        0,
        0);

      stars.Add(star);
    }

    return stars;
  }

  StarPoint NearestStarPoint(Vector3 spot, List<StarPoint> starPoints)
  {
    StarPoint nearbyPoint = new StarPoint(Vector3.zero, 0, 0, 0);

    if (starPoints == null) {
      return nearbyPoint;
    }

    float nearbyDistance = -1.0f;

    for (int i = 0; i < starPoints.Count; i++) {
      StarPoint starPoint = starPoints[i];
      float distance = Vector3.Distance(spot, starPoint.position);
      if (nearbyDistance == -1 || distance < nearbyDistance) {
        nearbyPoint = starPoint;
        nearbyDistance = distance;
      }
    }

    return nearbyPoint;
  }

 

 
}
