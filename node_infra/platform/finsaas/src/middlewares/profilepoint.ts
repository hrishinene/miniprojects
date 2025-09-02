// Create a middleware to profile performance of each endpoint
// It should capture current time before the request is processed
// and log the time taken to process the request after it is completed
import { Request, Response, NextFunction } from 'express';

export const profilePoint = (req: Request, res: Response, next: NextFunction) => {
  const start = process.hrtime();
  const fullRequest = req.url;
  // Think of using RequestContext framework to implement full fledged profilepoint later
  res.on('finish', () => {
    const duration = process.hrtime(start);
    const milliseconds = duration[0] * 1000 + duration[1] / 1e6; // Convert to milliseconds
    console.log(`${req.method} ${fullRequest} - ${milliseconds.toFixed(2)} ms`);
  });

  next();
};