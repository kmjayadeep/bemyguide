import type { LocationQuery, PlaceRecommendation } from "../types";

export class AIService {
  static async getRecommendations(
    query: LocationQuery,
    aiBinding: any
  ): Promise<PlaceRecommendation[]> {
    // Use AI to generate recommendations
    const aiResponse = await aiBinding.run(
      '@cf/meta/llama-3.3-70b-instruct-fp8-fast',
      {
        messages: [
          {
            role: 'system',
            content: 'You are a local guide assistant named \'bemyguide\'. Your task is to find relevant places for the user based on their query and location. ALWAYS respond with a valid JSON object containing a single key \'suggestions\' which is an array of places. Each place must have the following keys: \'name\', \'description\', \'category\', and \'distance_km\'. The \'description\' should be a concise, one-sentence summary. The \'distance_km\' should be the approximate distance in kilometers from the user\'s location to the suggested place. The \'category\' should be one of: \'Park\', \'Restaurant\', \'Museum\', \'Activity\', \'Landmark\', \'Shopping\', \'Other\'. Do not include any text outside of the JSON object.'
          },
          {
            role: 'user',
            content: `User query: '${query.query}'. My current location is latitude ${query.latitude} and longitude ${query.longitude}.`
          }
        ],
        max_tokens: 800,
        temperature: 0.3
      }
    );

    // Log the raw AI response for debugging
    console.log('Raw AI Response:', JSON.stringify(aiResponse, null, 2));

    // Parse the AI response
    let jsonResponse;
    if (aiResponse.response) {
      // The response is already a JSON object, not a string
      jsonResponse = aiResponse.response;
      console.log('Using aiResponse.response (already JSON):', jsonResponse);
    } else if (aiResponse.choices && aiResponse.choices.length > 0) {
      // This path might still need JSON parsing if it's a string
      const aiResponseText = aiResponse.choices[0].message.content;
      console.log('Using aiResponse.choices[0].message.content:', aiResponseText);
      
      if (typeof aiResponseText !== 'string') {
        console.error('AI response text is not a string:', aiResponseText);
        throw new Error('AI response is not a string');
      }

      try {
        jsonResponse = JSON.parse(aiResponseText);
        console.log('Successfully parsed JSON from choices:', JSON.stringify(jsonResponse, null, 2));
      } catch (parseError) {
        const errorMessage = parseError instanceof Error ? parseError.message : String(parseError);
        console.error('JSON parse error:', parseError);
        console.error('Failed to parse text:', aiResponseText);
        console.error('Text length:', aiResponseText.length);
        console.error('First 200 chars:', aiResponseText.substring(0, 200));
        throw new Error(`Failed to parse AI response as JSON: ${errorMessage}`);
      }
    } else {
      console.error('Unexpected AI response format. Available keys:', Object.keys(aiResponse));
      throw new Error('Unexpected AI response format');
    }

    if (!jsonResponse.suggestions || !Array.isArray(jsonResponse.suggestions)) {
      console.error('Invalid JSON structure. Expected suggestions array, got:', jsonResponse);
      throw new Error('AI response does not contain valid suggestions array');
    }

    console.log('Found suggestions:', jsonResponse.suggestions.length);

    const suggestions: PlaceRecommendation[] = jsonResponse.suggestions.map((place: any, index: number) => {
      console.log(`Processing suggestion ${index}:`, place);
      
      // Construct Google Maps URL from the search query
      const searchQuery = place.name || '';
      const encodedQuery = encodeURIComponent(searchQuery);
      const googleMapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodedQuery}`;
      
      return {
        name: place.name || '',
        description: place.description || '',
        category: place.category || 'Other',
        distance_km: typeof place.distance_km === 'number' ? place.distance_km : null,
        google_maps_url: googleMapsUrl
      };
    });

    console.log('Final processed suggestions:', suggestions);
    return suggestions;
  }
} 