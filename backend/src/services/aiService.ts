import type { LocationQuery, PlaceRecommendation } from "../types";

export class AIService {
  static async getRecommendations(
    query: LocationQuery,
    aiBinding: any
  ): Promise<PlaceRecommendation[]> {
    // Use AI to generate recommendations
    const aiResponse = await aiBinding.run(
      '@cf/meta/llama-3.1-8b-instruct',
      {
        messages: [
          {
            role: 'system',
            content: 'You are a local guide assistant named \'bemyguide\'. Your task is to find relevant places for the user based on their query and location. ALWAYS respond with a valid JSON object containing a single key \'suggestions\' which is an array of places. Each place must have the following keys: \'name\', \'description\', \'category\', \'distance_km\', \'website_url\', \'latitude\', and \'longitude\'. The \'description\' should be a concise, one-sentence summary. The \'distance_km\' should be the approximate distance in kilometers from the user\'s location to the suggested place. If you cannot find a website, set \'website_url\' to null. If you cannot find the exact coordinates, set \'latitude\' and \'longitude\' to null. The \'category\' should be one of: \'Park\', \'Restaurant\', \'Museum\', \'Activity\', \'Landmark\', \'Shopping\', \'Other\'. Do not include any text outside of the JSON object.'
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

    // Parse the AI response
    let aiResponseText = '';
    if (aiResponse.response) {
      aiResponseText = aiResponse.response;
    } else if (aiResponse.choices && aiResponse.choices.length > 0) {
      aiResponseText = aiResponse.choices[0].message.content;
    } else {
      throw new Error('Unexpected AI response format');
    }

    // Parse the JSON response from AI
    const jsonResponse = JSON.parse(aiResponseText);
    if (!jsonResponse.suggestions || !Array.isArray(jsonResponse.suggestions)) {
      throw new Error('AI response does not contain valid suggestions array');
    }

    const suggestions: PlaceRecommendation[] = jsonResponse.suggestions.map((place: any) => ({
      name: place.name || '',
      description: place.description || '',
      category: place.category || 'Other',
      distance_km: typeof place.distance_km === 'number' ? place.distance_km : null,
      website_url: place.website_url || null,
      latitude: typeof place.latitude === 'number' ? place.latitude : null,
      longitude: typeof place.longitude === 'number' ? place.longitude : null
    }));

    return suggestions;
  }
} 